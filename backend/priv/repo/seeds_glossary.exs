alias SkillsetEvaluator.Repo
alias SkillsetEvaluator.Glossary.Term

glossary_terms = [
  # === ERP terms (10) ===
  %{
    concept: "Bill of Quantities",
    domain: "ERP",
    term_en: "Bill of Quantities",
    term_de: "Leistungsverzeichnis",
    term_zh: "工程量清单",
    description_en:
      "A detailed list of materials, parts, and labour required for a construction project, used as the basis for tendering and cost control.",
    source: "aec_glossary"
  },
  %{
    concept: "Quantity Take-Off",
    domain: "ERP",
    term_en: "Quantity Take-Off",
    term_de: "Massenermittlung",
    term_zh: "工程量计算",
    description_en:
      "The process of measuring and calculating the quantities of materials and labour needed from construction drawings and specifications.",
    source: "aec_glossary"
  },
  %{
    concept: "Change Order",
    domain: "ERP",
    term_en: "Change Order",
    term_de: "Nachtragsauftrag",
    term_zh: "变更令",
    description_en:
      "A formal document that modifies the original scope, cost, or schedule of a construction contract after it has been signed.",
    source: "aec_glossary"
  },
  %{
    concept: "Contract Award",
    domain: "ERP",
    term_en: "Contract Award",
    term_de: "Zuschlag",
    term_zh: "合同授予",
    description_en:
      "The formal decision to grant a construction contract to a particular bidder following the tendering process.",
    source: "aec_glossary"
  },
  %{
    concept: "Progress Billing",
    domain: "ERP",
    term_en: "Progress Billing",
    term_de: "Abschlagsrechnung",
    term_zh: "工程进度款",
    description_en:
      "Periodic invoices issued during a construction project based on the percentage of work completed to date.",
    source: "aec_glossary"
  },
  %{
    concept: "Final Invoice",
    domain: "ERP",
    term_en: "Final Invoice",
    term_de: "Schlussrechnung",
    term_zh: "竣工结算",
    description_en:
      "The concluding invoice for a construction project that reconciles all previous progress payments with the final contract value.",
    source: "aec_glossary"
  },
  %{
    concept: "Cost Codes",
    domain: "ERP",
    term_en: "Cost Codes",
    term_de: "Kostenstellen",
    term_zh: "费用编码",
    description_en:
      "A structured numbering system used to categorize and track construction expenditures against budget line items.",
    source: "aec_glossary"
  },
  %{
    concept: "Requisitions",
    domain: "ERP",
    term_en: "Requisitions",
    term_de: "Bedarfsanforderungen",
    term_zh: "采购申请",
    description_en:
      "Formal internal requests to procure materials, equipment, or services needed for a construction project.",
    source: "aec_glossary"
  },
  %{
    concept: "WBS",
    domain: "ERP",
    term_en: "WBS",
    term_de: "Projektstrukturplan",
    term_zh: "工作分解结构",
    description_en:
      "Work Breakdown Structure: a hierarchical decomposition of a project into manageable work packages for planning and cost tracking.",
    source: "aec_glossary"
  },
  %{
    concept: "Cost Estimation",
    domain: "ERP",
    term_en: "Cost Estimation",
    term_de: "Kostenermittlung",
    term_zh: "造价估算",
    description_en:
      "The process of forecasting the total cost of a construction project based on design documents, historical data, and market conditions.",
    source: "aec_glossary"
  },

  # === BIM terms (7) ===
  %{
    concept: "BIM",
    domain: "BIM",
    term_en: "BIM",
    term_de: "BIM",
    term_zh: "建筑信息模型",
    description_en:
      "Building Information Modeling: a digital representation of the physical and functional characteristics of a facility, enabling collaborative design and construction.",
    source: "aec_glossary"
  },
  %{
    concept: "IFC",
    domain: "BIM",
    term_en: "IFC",
    term_de: "IFC",
    term_zh: "IFC工业基础类",
    description_en:
      "Industry Foundation Classes: an open, vendor-neutral data schema for exchanging BIM data across different software platforms.",
    source: "aec_glossary"
  },
  %{
    concept: "CDE",
    domain: "BIM",
    term_en: "CDE",
    term_de: "CDE",
    term_zh: "公共数据环境",
    description_en:
      "Common Data Environment: a single source of information used to collect, manage, and share project data among all stakeholders.",
    source: "aec_glossary"
  },
  %{
    concept: "Clash Detection",
    domain: "BIM",
    term_en: "Clash Detection",
    term_de: "Kollisionsprüfung",
    term_zh: "碰撞检测",
    description_en:
      "The automated process of identifying geometric conflicts between building elements in a BIM model before construction begins.",
    source: "aec_glossary"
  },
  %{
    concept: "Digital Twin",
    domain: "BIM",
    term_en: "Digital Twin",
    term_de: "Digitaler Zwilling",
    term_zh: "数字孪生",
    description_en:
      "A dynamic digital replica of a physical asset or system that is continuously updated with real-time data for monitoring and simulation.",
    source: "aec_glossary"
  },
  %{
    concept: "Point Cloud",
    domain: "BIM",
    term_en: "Point Cloud",
    term_de: "Punktwolke",
    term_zh: "点云",
    description_en:
      "A set of 3D data points captured by laser scanning or photogrammetry, used to create as-built models of existing structures.",
    source: "aec_glossary"
  },
  %{
    concept: "LOD",
    domain: "BIM",
    term_en: "LOD",
    term_de: "LOD",
    term_zh: "模型深度等级",
    description_en:
      "Level of Development: a classification that defines the degree of detail and reliability of information in a BIM element at various project stages.",
    source: "aec_glossary"
  },

  # === AI terms (5) ===
  %{
    concept: "Automated QTO",
    domain: "AI",
    term_en: "Automated QTO",
    term_de: "Automatisierte Massenermittlung",
    term_zh: "自动工程量计算",
    description_en:
      "The use of AI and machine learning algorithms to automatically extract quantities from BIM models or 2D drawings, reducing manual measurement effort.",
    source: "aec_glossary"
  },
  %{
    concept: "Predictive Scheduling",
    domain: "AI",
    term_en: "Predictive Scheduling",
    term_de: "Prädiktive Terminplanung",
    term_zh: "预测性排程",
    description_en:
      "AI-driven project scheduling that forecasts delays, optimizes task sequences, and adapts timelines based on historical project data.",
    source: "aec_glossary"
  },
  %{
    concept: "AI-driven Estimating",
    domain: "AI",
    term_en: "AI-driven Estimating",
    term_de: "KI-gestützte Kalkulation",
    term_zh: "AI驱动造价",
    description_en:
      "The application of artificial intelligence to generate cost estimates by analysing past project data, market trends, and design parameters.",
    source: "aec_glossary"
  },
  %{
    concept: "Computer Vision",
    domain: "AI",
    term_en: "Computer Vision",
    term_de: "Bildverarbeitung",
    term_zh: "计算机视觉",
    description_en:
      "AI technology that processes images and video from construction sites to monitor progress, detect safety issues, and verify quality.",
    source: "aec_glossary"
  },
  %{
    concept: "Predictive Maintenance",
    domain: "AI",
    term_en: "Predictive Maintenance",
    term_de: "Vorausschauende Instandhaltung",
    term_zh: "预测性维护",
    description_en:
      "The use of sensor data and machine learning to anticipate equipment failures and schedule maintenance before breakdowns occur.",
    source: "aec_glossary"
  },

  # === Procurement terms (3) ===
  %{
    concept: "RfQ",
    domain: "Procurement",
    term_en: "RfQ",
    term_de: "Angebotsanfrage",
    term_zh: "询价单",
    description_en:
      "Request for Quotation: a formal document sent to suppliers inviting them to submit pricing for specific materials or services.",
    source: "aec_glossary"
  },
  %{
    concept: "Quotes/Tenders",
    domain: "Procurement",
    term_en: "Quotes/Tenders",
    term_de: "Angebote/Ausschreibungen",
    term_zh: "报价/投标",
    description_en:
      "Formal price proposals submitted by contractors or suppliers in response to a request, forming the basis for contract negotiation.",
    source: "aec_glossary"
  },
  %{
    concept: "Subcontractor Mgmt",
    domain: "Procurement",
    term_en: "Subcontractor Mgmt",
    term_de: "Nachunternehmerverwaltung",
    term_zh: "分包管理",
    description_en:
      "The coordination, monitoring, and administration of subcontracted work packages to ensure quality, schedule, and budget compliance.",
    source: "aec_glossary"
  }
]

for attrs <- glossary_terms do
  case Repo.get_by(Term, concept: attrs.concept, domain: attrs.domain) do
    nil ->
      %Term{}
      |> Term.changeset(attrs)
      |> Repo.insert!()
      IO.puts("  Seeded glossary term: #{attrs.concept} (#{attrs.domain})")

    _existing ->
      IO.puts("  Glossary term exists: #{attrs.concept} (#{attrs.domain})")
  end
end

IO.puts("Glossary seeding complete: #{length(glossary_terms)} terms processed.")
