defmodule SkillsetEvaluator.LLM.Guardrails do
  @moduledoc """
  Input and output guardrails for LLM interactions.

  Input guardrails (pre-LLM):
  - Length check (max 2000 chars)
  - Language detection via Unicode script blocks
  - Prompt injection detection
  - PII scan (warn but don't block)

  Output guardrails (post-LLM):
  - Strip code blocks
  - Score boundary check (0-5)
  - Data leak check for "user" role
  """

  import Ecto.Query

  require Logger

  @max_input_length 2000

  # Patterns that suggest prompt injection
  @injection_patterns [
    ~r/ignore\s+(all\s+)?(previous|above|prior)\s+(instructions|prompts|rules)/i,
    ~r/you\s+are\s+now\s+(a|an)\s+/i,
    ~r/system\s*prompt/i,
    ~r/\bDAN\b.*\bmode\b/i,
    ~r/jailbreak/i,
    ~r/pretend\s+you\s+(are|have)/i,
    ~r/disregard\s+(your|all|any)/i,
    ~r/override\s+(your|the|all)/i
  ]

  # --- Input Guardrails ---

  @doc """
  Validates user input before sending to LLM.
  Returns :ok or {:error, reason}.
  """
  def validate_input(content) when is_binary(content) do
    with :ok <- check_length(content),
         :ok <- check_injection(content) do
      scan_pii(content)
      :ok
    end
  end

  def validate_input(_), do: {:error, "Content must be a string"}

  defp check_length(content) do
    if String.length(content) > @max_input_length do
      {:error, "Message too long. Maximum #{@max_input_length} characters allowed."}
    else
      :ok
    end
  end

  defp check_injection(content) do
    if Enum.any?(@injection_patterns, &Regex.match?(&1, content)) do
      {:error, "Message contains disallowed patterns."}
    else
      :ok
    end
  end

  defp scan_pii(content) do
    # Simple PII detection — warn but don't block
    pii_patterns = [
      {~r/\b\d{3}[-.]?\d{2}[-.]?\d{4}\b/, "SSN-like number"},
      {~r/\b[A-Z]{2}\d{6,8}\b/, "passport-like number"},
      {~r/\b\d{4}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4}\b/, "credit card-like number"}
    ]

    Enum.each(pii_patterns, fn {pattern, label} ->
      if Regex.match?(pattern, content) do
        Logger.warning("PII detected in chat input: #{label}")
      end
    end)
  end

  @doc """
  Detects the likely language of the input based on Unicode script blocks.
  Returns "zh" for CJK, "en" for Latin (default).
  """
  def detect_language(content) do
    cjk_count =
      content
      |> String.to_charlist()
      |> Enum.count(fn codepoint ->
        codepoint >= 0x4E00 && codepoint <= 0x9FFF
      end)

    total = String.length(content)

    if total > 0 && cjk_count / total > 0.3 do
      "zh"
    else
      "en"
    end
  end

  # --- Output Guardrails ---

  @doc """
  Validates and cleans LLM output before returning to user.
  Accepts either a User struct or a role string for backward compatibility.
  """
  def validate_output(content, %{role: role} = user) when is_binary(content) do
    content
    |> strip_code_blocks()
    |> check_score_boundaries()
    |> check_data_leaks(role)
    |> check_cross_user_leaks(user)
  end

  def validate_output(content, user_role) when is_binary(content) and is_binary(user_role) do
    content
    |> strip_code_blocks()
    |> check_score_boundaries()
    |> check_data_leaks(user_role)
  end

  def validate_output(content, _user_role), do: {:ok, to_string(content)}

  defp strip_code_blocks(content) do
    # Remove executable code blocks but keep text content
    cleaned =
      content
      |> String.replace(
        ~r/```(?:python|javascript|ruby|elixir|bash|sh|sql)\n[\s\S]*?```/,
        "[code block removed]"
      )

    {:ok, cleaned}
  end

  defp check_score_boundaries({:ok, content}) do
    # Check for scores outside 0-5 range in output
    cleaned =
      Regex.replace(~r/\b(\d+(?:\.\d+)?)\s*(?:\/\s*5|out\s+of\s+5)/, content, fn full,
                                                                                 score_str ->
        case Float.parse(score_str) do
          {score, _} when score >= 0 and score <= 5 -> full
          {score, _} when score > 5 -> "5.0/5"
          {score, _} when score < 0 -> "0.0/5"
          _ -> full
        end
      end)

    {:ok, cleaned}
  end

  defp check_score_boundaries(error), do: error

  defp check_data_leaks({:ok, content}, "user") do
    # For regular users, check if output contains other users' data patterns
    if Regex.match?(~r/(?:all\s+users|all\s+employees|full\s+team\s+roster)/i, content) do
      Logger.warning("Potential data leak in LLM output for user role")

      {:ok,
       String.replace(
         content,
         ~r/(?:all\s+users|all\s+employees|full\s+team\s+roster)/i,
         "[restricted]"
       )}
    else
      {:ok, content}
    end
  end

  defp check_data_leaks({:ok, content}, _role), do: {:ok, content}
  defp check_data_leaks(error, _role), do: error

  # Enhanced cross-user data leak detection for regular users
  defp check_cross_user_leaks({:ok, content}, %{role: "user"} = user) do
    # For regular users, check if output mentions other users' names or emails
    # by querying the DB for all user names and checking if any appear in the output
    other_users =
      SkillsetEvaluator.Repo.all(
        from(u in SkillsetEvaluator.Accounts.User,
          where: u.id != ^user.id and u.active == true,
          select: {u.name, u.email}
        )
      )

    leaked_names =
      Enum.filter(other_users, fn {name, email} ->
        name_match =
          name && String.length(name) > 3 &&
            String.contains?(String.downcase(content), String.downcase(name))

        email_match = email && String.contains?(String.downcase(content), String.downcase(email))
        name_match || email_match
      end)

    if Enum.empty?(leaked_names) do
      {:ok, content}
    else
      Logger.warning(
        "Data leak detected: LLM output for user #{user.id} mentions #{length(leaked_names)} other user(s)"
      )

      # Redact the leaked names
      cleaned =
        Enum.reduce(leaked_names, content, fn {name, email}, acc ->
          acc = if name, do: String.replace(acc, name, "[redacted]", global: true), else: acc
          if email, do: String.replace(acc, email, "[redacted]", global: true), else: acc
        end)

      {:ok, cleaned}
    end
  end

  defp check_cross_user_leaks({:ok, content}, _user), do: {:ok, content}
  defp check_cross_user_leaks(error, _user), do: error
end
