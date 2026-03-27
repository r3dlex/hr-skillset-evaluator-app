# Multilingual AEC and construction ERP glossary across four languages

**This glossary maps 150+ construction industry terms across German, English, Portuguese-Brazilian, and Spanish**, covering construction ERP workflows, BIM standards, procurement frameworks, AI/analytics, and regulatory compliance. The terminology reflects how modern AEC platforms — from German-origin systems like RIB iTWO and NEVARIS to global platforms like Procore and Autodesk Construction Cloud — actually localize their interfaces across markets. Three critical patterns emerged: English BIM acronyms (IFC, CDE, BCF) remain untranslated globally, German construction terminology is uniquely codified through VOB/HOAI/DIN frameworks with no direct equivalents elsewhere, and Brazilian Portuguese has developed an entirely independent terminology ecosystem anchored in SINAPI cost databases and BDI markup structures.

---

## Core construction ERP terminology

The foundation of any construction ERP system rests on terms for scoping, measuring, billing, and managing costs. These terms diverge sharply across markets because they reflect different legal and contractual traditions.

| # | Concept | DE | EN | PT-BR | ES | Domain |
|---|---------|----|----|-------|----|----|
| 1 | Bill of Quantities | **Leistungsverzeichnis (LV)** | Bill of Quantities (BoQ); US: Schedule of Values (SoV) | Planilha Orçamentária; Planilha de Quantitativos | Catálogo de Conceptos (MX); Presupuesto Detallado (ES); Cuadro de Precios | ERP |
| 2 | Quantity Take-Off | **Aufmaß** (site measurement); **Massenermittlung** (from drawings) | Quantity Take-Off (QTO); Takeoff | Levantamento de Quantitativos | Cubicación; Medición de Cantidades; Generador de Obra (MX) | ERP |
| 3 | Change Orders | **Nachträge** | Change Order (US); **Variation** (UK/AU) | Aditivo Contratual; Termo Aditivo | Orden de Cambio (LatAm); Variación (FIDIC); Modificación de Contrato (ES) | ERP |
| 4 | Contract Award | **Vergabe** (process); **Zuschlag** (act of awarding) | Contract Award; Tender Award | Adjudicação; Homologação (public) | Adjudicación (del contrato) | ERP |
| 5 | Progress Billing | **Abschlagsrechnung** | Pay Application (US); Interim Valuation (UK); **Progress Claim** (AU) | **Medição** (de obra); Boletim de Medição | Certificación de Obra (ES); Estimación de Avance (MX); Estado de Pago (CL) | ERP |
| 6 | Final Invoice | **Schlussrechnung** | Final Invoice (US); **Final Account** (UK) | Fatura Final; Medição Final | Factura Final; Liquidación Final | ERP |
| 7 | Cost Codes | **Kostenarten**; Kostengruppen per **DIN 276** (KG 100–800) | Cost Codes; CSI MasterFormat (US); NRM (UK) | Códigos de Custo; classificação SINAPI | Códigos de Costo; Partidas Presupuestarias | ERP |
| 8 | Requisitions | **Bestellanforderung (BANF)** | Purchase Requisition | Requisição de Compra; Solicitação de Compra | Requisición de Compra; Solicitud de Compra | ERP |
| 9 | RfQ | **Angebotsanfrage** | Request for Quotation (RfQ) | Solicitação de Cotação; Pedido de Cotação | Solicitud de Cotización; Petición de Oferta | ERP |
| 10 | Quotes / Tenders | **Angebot** (quote); **Ausschreibung** (tender process) | **Bid** (US); **Tender** (UK/AU) | Proposta; Cotação; Licitação (public) | Oferta; Presupuesto; Licitación (public) | ERP |
| 11 | Subcontractor Mgmt | **Nachunternehmermanagement** (NU = Nachunternehmer) | Subcontractor Management | Gestão de Subempreiteiros; Gestão de Terceirizados | Gestión de Subcontratistas | ERP |
| 12 | Plant / Equipment | **Gerätemanagement**; Baumaschinenmanagement | Equipment Management (US); **Plant Management** (UK/AU) | Gestão de Equipamentos; Controle de Máquinas | Gestión de Maquinaria; Gestión de Equipo Pesado | ERP |
| 13 | Assemblies | **Baugruppen**; Leistungspositionen | Assemblies; Composite Items; Build-ups | **Composições** (de custos); Composições Unitárias | Composiciones de Precios; **APU** (Análisis de Precios Unitarios) | ERP |
| 14 | Markup / Surcharges | **Zuschläge** (Gemeinkosten + Gewinn + Wagnis) | Markup; Overhead & Profit (O&P) | **BDI** (Benefícios e Despesas Indiretas) | Costos Indirectos y Utilidad; Gastos Generales | ERP |
| 15 | Allowances | **Bedarfspositionen**; Pauschalansätze | Allowances (US); **Provisional Sums** / **Prime Cost Sums** (UK) | Verbas (VB); Provisões | Partidas Alzadas; Sumas Provisionales | ERP |
| 16 | Joint Ventures | **ARGE** (Arbeitsgemeinschaft) | Joint Venture (JV); Consortium | Consórcio (de construção) | UTE (Unión Temporal de Empresas) (ES); Consorcio (LatAm) | ERP |
| 17 | WBS | **Projektstrukturplan (PSP)** | Work Breakdown Structure (WBS) | **EAP** (Estrutura Analítica do Projeto) | **EDT** (Estructura de Desglose del Trabajo) | ERP |
| 18 | Cost Estimation | **Kostenschätzung** → **Kostenberechnung** → **Kostenanschlag** → **Kostenfeststellung** (DIN 276 progression) | Cost Estimate; Cost Plan | Estimativa de Custos; Orçamento Detalhado | Estimación de Costos; Presupuesto Estimativo | ERP |
| 19 | Schedule of Rates | **Einheitspreisliste** | Schedule of Values (US); Schedule of Rates (UK) | Tabela de Preços Unitários; SINAPI/SICRO | Cuadro de Precios Unitarios | ERP |
| 20 | Retention | **Sicherheitseinbehalt** (typically 5%, VOB/B §17) | **Retainage** (US, 5–10%); **Retention** (UK/AU, 5%) | Retenção; Caução Contratual | Retención de Garantía; Fondo de Retención | ERP |

The German term **Aufmaß** deserves special attention: it specifically denotes on-site measurement of work actually executed (for payment verification), distinct from **Massenermittlung**, which is pre-construction quantity calculation from drawings. No other language captures this distinction in a single word. In Procore's German localization, "Change Order" becomes **Nachtragsauftrag**, while PlanRadar uses **Mängelliste** for "Punch List" — a term that itself splits three ways in English: "Punch List" (US), "Snag List" (UK), and "Defects List" (AU).

---

## Procurement and contract framework terms

Construction contracts vary enormously by jurisdiction. Germany's **VOB** framework, the UK's **NEC/JCT** contracts, the US **AIA** documents, and the internationally used **FIDIC** suite each carry their own vocabulary that resists direct translation.

| # | Concept | DE | EN | PT-BR | ES | Domain |
|---|---------|----|----|-------|----|----|
| 1 | German contract framework | **VOB** (Vergabe- und Vertragsordnung für Bauleistungen): Part A (procurement), Part B (contract conditions), Part C (technical specs/ATV) | No direct equivalent; closest: JCT (UK), AIA (US) | No equivalent; Brazil uses Lei 14.133/2021 | No equivalent; Spain uses LCSP | Procurement |
| 2 | Fee regulations | **HOAI** (Honorarordnung): 9 Leistungsphasen (LP1–LP9) | RIBA Plan of Work (UK, 8 stages); AIA fee structures (US) | No binding scale; CONFEA/CREA guidelines | No binding scale post-EU liberalization | Procurement |
| 3 | FIDIC Red Book | FIDIC-Vertragsbedingungen – Rotes Buch | Conditions of Contract for Construction | Condições Contratuais FIDIC – Livro Vermelho | Condiciones de Contrato FIDIC – Libro Rojo | Procurement |
| 4 | FIDIC Yellow Book | Gelbes Buch (Anlagen + Design-Build) | Conditions of Contract for Plant and Design-Build | Livro Amarelo | Libro Amarillo | Procurement |
| 5 | FIDIC Silver Book | Silbernes Buch (EPC/Turnkey) | Conditions of Contract for EPC/Turnkey | Livro Prata | Libro Plata | Procurement |
| 6 | Lump Sum | **Pauschalvertrag** | Lump Sum / Fixed Price Contract | Empreitada por Preço Global | Precio Alzado (MX/ES); **Suma Alzada** (CL/CO/PE/AR) | Procurement |
| 7 | Unit Price | **Einheitspreisvertrag** (most common under VOB) | Unit Price Contract; Re-measurement Contract (UK) | Empreitada por Preço Unitário | Contrato a Precios Unitarios | Procurement |
| 8 | Cost-Plus | **Selbstkostenerstattungsvertrag** | Cost-Plus; Cost Reimbursable | **Construção por Administração** | Contrato por Administración | Procurement |
| 9 | Design-Build | **Totalunternehmer (TU)** (full design + build); **Generalunternehmer (GU)** (build, some design) | Design-Build (US); Design and Build (UK) | Contratação Integrada (public); Projeto e Construção | Diseño-Construcción; Llave en Mano (turnkey) | Procurement |
| 10 | Design-Bid-Build | **Einzelvergabe** / Traditionelle Vergabe | Design-Bid-Build (US); Traditional Procurement (UK) | Método Tradicional de Contratação | Diseño-Licitación-Construcción | Procurement |
| 11 | GMP | **GMP-Vertrag** / Garantierter Maximalpreis | Guaranteed Maximum Price (GMP) | Preço Máximo Garantido (PMG) | Precio Máximo Garantizado (PMG) | Procurement |
| 12 | CM at Risk | Baumanagement mit Risikoübernahme | Construction Manager at Risk (CMAR) | Gerenciamento de Construção em Risco | Gestión de Construcción en Riesgo | Procurement |
| 13 | PPP/PFI | **ÖPP** (Öffentlich-Private Partnerschaft) | PPP / P3 (US); PFI (UK, legacy) | **PPP** (Parceria Público-Privada, Lei 11.079/2004) | **APP** (Asociación Público-Privada); Concesión | Procurement |
| 14 | Performance Bond | **Vertragserfüllungsbürgschaft** | Performance Bond / Performance Guarantee | Seguro-Garantia de Execução; Fiança Bancária | **Fianza de Cumplimiento** (MX); Póliza de Cumplimiento (CO); **Boleta de Garantía** (CL) | Procurement |
| 15 | Bank Guarantee | **Bankbürgschaft** / Avalbürgschaft | Bank Guarantee; Letter of Credit (US) | Garantia Bancária; Fiança Bancária | Garantía Bancaria; Aval Bancario | Procurement |
| 16 | Warranty Period | **Gewährleistungsfrist** (VOB: 4 yrs; BGB: 5 yrs) | Warranty Period (US); **Defects Liability Period** (UK/AU) | Prazo de Garantia (Civil Code Art. 618: 5 yrs structural) | Período de Garantía (Spain LOE: **10 yrs** structural, 3 yrs habitability, 1 yr finishes) | Procurement |
| 17 | Completion milestone | **Abnahme** (triggers warranty, risk transfer, burden of proof reversal) | **Substantial Completion** (US); **Practical Completion** (UK/AU) | Recebimento Provisório → Recebimento Definitivo | Recepción Provisional → Recepción Definitiva | Procurement |

The German **Abnahme** is arguably the single most consequential milestone in any construction contract — it simultaneously triggers risk transfer, reverses the burden of proof for defects, starts the warranty clock, and obligates the Schlussrechnung. Austrian practice uses **Übernahme** (with deemed acceptance after 30 days per ÖNORM B 2110), while Swiss contracts under **SIA 118** follow distinct Mängelrüge (defect notice) procedures.

---

## BIM and openBIM standards terminology

BIM terminology shows a clear pattern: **technical acronyms remain in English globally** (IFC, BCF, CDE, COBie), while descriptive concepts get translated. Germany and Brazil have each developed local acronym replacements for a few key terms.

| # | Concept | DE | EN | PT-BR | ES | Acronym translated? |
|---|---------|----|----|-------|----|----|
| 1 | BIM | BIM (Bauwerksinformationsmodellierung, formal) | Building Information Modeling (BIM) | BIM (Modelagem da Informação da Construção) | BIM (Modelado de Información de la Construcción) | No — "BIM" universal |
| 2 | IFC | IFC | Industry Foundation Classes (IFC) | IFC | IFC | No |
| 3 | CDE | **Gemeinsame Datenumgebung** (CDE) | Common Data Environment (CDE) | **Ambiente Comum de Dados** (CDE) | **Entorno Común de Datos** (CDE) | English acronym preserved |
| 4 | LOD | Fertigstellungsgrad; → now **LOIN** (Informationsbedarfstiefe per DIN EN 17412-1) | Level of Development (LOD) | **Nível de Desenvolvimento (ND)** | Nivel de Desarrollo (LOD) | DE → LOIN; PT-BR → ND |
| 5 | LOI | Informationsgehalt (LOI) | Level of Information (LOI) | Nível de Informação (LOI) | Nivel de Información (LOI) | No |
| 6 | LOG | Geometrischer Detaillierungsgrad (LOG) | Level of Geometry (LOG) | Nível de Geometria (LOG) | Nivel de Geometría (LOG) | No |
| 7 | BCF | BIM Collaboration Format (BCF) | BIM Collaboration Format (BCF) | BCF | BCF | No |
| 8 | BEP | **BAP** (BIM-Abwicklungsplan) | BIM Execution Plan (BEP) | **PEB** (Plano de Execução BIM) | Plan de Ejecución BIM (BEP/PEB) | **Yes** — DE: BAP; PT-BR: PEB |
| 9 | EIR | **AIA** (Auftraggeber-Informationsanforderungen) | Exchange Information Requirements (EIR) | Requisitos de Informação do Contratante (EIR) | Requisitos de Información del Cliente (EIR) | **Yes** — DE: AIA |
| 10 | Clash Detection | **Kollisionsprüfung** | Clash Detection | Detecção de Interferências; Detecção de Colisões | Detección de Colisiones; Detección de Interferencias | Fully translated |
| 11 | Federated Model | **Koordinationsmodell** | Federated Model | Modelo Federado; Modelo Coordenado | Modelo Federado | Translated |
| 12 | Digital Twin | **Digitaler Zwilling** | Digital Twin | **Gêmeo Digital** | **Gemelo Digital** | Fully translated |
| 13 | AIM | Bestandsinformationsmodell (AIM) | Asset Information Model (AIM) | Modelo de Informação do Ativo (AIM) | Modelo de Información del Activo (AIM) | No |
| 14 | PIM | Projektinformationsmodell (PIM) | Project Information Model (PIM) | Modelo de Informação do Projeto (PIM) | Modelo de Información del Proyecto (PIM) | No |
| 15 | Point Cloud | **Punktwolke** | Point Cloud | **Nuvem de Pontos** | **Nube de Puntos** | Fully translated |
| 16 | Scan-to-BIM | Scan-to-BIM | Scan-to-BIM | Scan-to-BIM | Scan-to-BIM | No — English loanword |
| 17 | As-built Model | As-built-Modell; **Bestandsmodell** | As-built Model / Record Model | Modelo As-Built | Modelo As-Built | "As-built" used as loanword |
| 18 | 4D BIM | 4D BIM (Terminplanung/Bauablaufsimulation) | 4D BIM (time/scheduling) | 4D BIM (Planejamento/Cronograma) | 4D BIM (Planificación temporal) | No |
| 19 | 5D BIM | 5D BIM (Kostenplanung) | 5D BIM (cost) | 5D BIM (Orçamento/Custos) | 5D BIM (Coste/Estimación) | No |
| 20 | COBie | COBie | Construction Operations Building Information Exchange | COBie | COBie | No |
| 21 | MVD | Modellansichtsdefinition (MVD) | Model View Definition (MVD) | MVD | MVD | No |
| 22 | IDS | IDS | Information Delivery Specification (IDS) | IDS | IDS | No |
| 23 | bSDD | bSDD | buildingSMART Data Dictionary | bSDD | bSDD | No |
| 24 | openBIM | openBIM | openBIM | openBIM | openBIM | No — proper noun |
| 25 | OIR | Organisations-Informations-Anforderungen (OIR) | Organizational Information Requirements | Requisitos de Informação da Organização | Requisitos de Información de la Organización | No |

Germany's shift from **LOD** to **LOIN** (Level of Information Need, per DIN EN 17412-1) reflects a conceptual evolution: LOIN combines geometry (LOG) and alphanumeric information (LOI) into a unified framework. This is gaining traction in ISO standards and may eventually replace LOD globally. The BEP/BAP split is notable — Germany's **BAP** (BIM-Abwicklungsplan) and Brazil's **PEB** (Plano de Execução BIM) are among the few BIM acronyms that received genuine local replacements rather than preserving the English original.

---

## AI and analytics terms used in AEC platforms

AI terminology in construction is relatively new and largely originates in English. Translations across languages tend to be descriptive rather than standardized. German consistently uses the prefix **KI-** (Künstliche Intelligenz) where English uses "AI-."

| # | Concept | DE | EN | PT-BR | ES | Domain |
|---|---------|----|----|-------|----|----|
| 1 | Automated Quantity Take-Off | **Automatisierte Mengenermittlung** | Automated Quantity Take-Off | Levantamento Automático de Quantitativos | Medición Automática de Cantidades | AI |
| 2 | Predictive Scheduling | **KI-gestützte Terminplanung**; Prädiktive Terminplanung | Predictive Scheduling | Planejamento Preditivo; Programação Preditiva | Planificación Predictiva | AI |
| 3 | Intelligent Document Routing | Intelligente Dokumentenweiterleitung | Intelligent Document Routing | Roteamento Inteligente de Documentos | Enrutamiento Inteligente de Documentos | AI |
| 4 | AI-driven Estimating | **KI-gestützte Kalkulation** (BRZ: "KI-Kalkulationsassistent") | AI-driven Estimating; AI-Powered Cost Estimation | Estimativa Baseada em IA; Orçamentação com IA | Estimación Basada en IA; Presupuestación con IA | AI |
| 5 | Computer Vision for Site Monitoring | Computergestützte Bildanalyse für Baustellenüberwachung | Computer Vision for Site Monitoring | Visão Computacional para Monitoramento de Canteiro | Visión por Computadora para Monitoreo de Obra | AI |
| 6 | Generative Design | **Generatives Design**; Generativer Entwurf | Generative Design | Design Generativo; Projeto Generativo | Diseño Generativo | AI |
| 7 | NLP for RFI Triage | NLP-basierte RFI-Vorsortierung | NLP for RFI Triage | Processamento de Linguagem Natural para Triagem de RFI | PLN para Triaje de RFI (Solicitud de Información) | AI |
| 8 | ML for Cost Prediction | **ML-basierte Kostenvorhersage** | Machine Learning for Cost Prediction | Aprendizado de Máquina para Previsão de Custos | Aprendizaje Automático para Predicción de Costos | AI |
| 9 | Digital Twin Analytics | Analyse des Digitalen Zwillings | Digital Twin Analytics | Analítica de Gêmeo Digital | Analítica del Gemelo Digital | AI |
| 10 | IoT Sensor Integration | IoT-Sensorintegration | IoT Sensor Integration | Integração de Sensores IoT | Integración de Sensores IoT | AI |
| 11 | Automated Compliance Checking | **Automatisierte Normenprüfung**; Automatische Regelprüfung | Automated Compliance Checking; Automated Code Checking | Verificação Automática de Conformidade | Verificación Automática de Cumplimiento | AI |
| 12 | AI-based Risk Assessment | **KI-basierte Risikobewertung** | AI-based Risk Assessment | Avaliação de Risco Baseada em IA | Evaluación de Riesgos Basada en IA | AI |
| 13 | Predictive Maintenance | **Vorausschauende Wartung**; Prädiktive Instandhaltung | Predictive Maintenance | **Manutenção Preditiva** | **Mantenimiento Predictivo** | AI |
| 14 | Automated Progress Tracking | Automatische Fortschrittsverfolgung | Automated Progress Tracking | Acompanhamento Automático do Progresso da Obra | Seguimiento Automático del Avance de Obra | AI |
| 15 | Image Recognition for Defects | **KI-basierte Mängelerkennung** | Image Recognition for Defect Detection | Reconhecimento de Imagem para Detecção de Defeitos | Reconocimiento de Imágenes para Detección de Defectos | AI |
| 16 | RPA in Construction | Robotergesteuerte Prozessautomatisierung (RPA) | Robotic Process Automation (RPA) | Automação Robótica de Processos (RPA) | Automatización Robótica de Procesos (RPA) | AI |
| 17 | Anomaly Detection | Anomalieerkennung | Anomaly Detection | Detecção de Anomalias | Detección de Anomalías | AI |
| 18 | AI Schedule Optimization | KI-basierte Terminoptimierung | AI-based Schedule Optimization | Otimização de Cronograma com IA | Optimización de Cronograma con IA | AI |
| 19 | Automated Safety Monitoring | **KI-gestütztes Sicherheitsmonitoring** | Automated Safety Monitoring | Monitoramento Automatizado de Segurança | Monitoreo Automatizado de Seguridad | AI |

**BRZ** (German construction ERP) stands out as the first DACH-market platform to embed AI at the product core, offering a **KI-Kalkulationsassistent** that analyzes specification texts to auto-classify and price line items. Autodesk's **Construction IQ** (branded, untranslated across all localizations) uses ML for safety and quality risk scoring in BIM 360/ACC. Procore recently launched an AI-powered **Draft RFI Agent** for automated RFI generation.

---

## Regulatory and compliance terms

| # | Concept | DE | EN | PT-BR | ES | Domain |
|---|---------|----|----|-------|----|----|
| 1 | Building Permit | **Baugenehmigung** (DE); **Baubewilligung** (AT/CH) | Building Permit (US); Planning Permission (UK); Development Approval (AU) | **Alvará de Construção** | Licencia de Construcción (MX/CO); **Permiso de Edificación** (CL) | Regulatory |
| 2 | EIA | **Umweltverträglichkeitsprüfung (UVP)** | Environmental Impact Assessment (EIA) | **Estudo de Impacto Ambiental (EIA)** + RIMA | Evaluación de Impacto Ambiental (EIA) | Regulatory |
| 3 | Occupational Safety | **Arbeitsschutzgesetz (ArbSchG)**; Baustellenverordnung (BaustellV) | OSHA (US); CDM Regulations (UK); WHS Act (AU) | **NR-18** (Normas Regulamentadoras) | Prevención de Riesgos Laborales (LPRL) | Regulatory |
| 4 | Quality Management | Qualitätsmanagement ISO 9001 (QMS) | Quality Management System ISO 9001 | SGQ ISO 9001; **PBQP-H** (Brazil-specific) | Sistema de Gestión de la Calidad ISO 9001 | Regulatory |
| 5 | Energy Performance | **Energieausweis** (DE); **GEAK** (CH) | EPC (UK); HERS/ENERGY STAR (US); NABERS (AU) | **ENCE/Procel Edifica** | Certificado de Eficiencia Energética (CEE) | Regulatory |
| 6 | DGNB | DGNB-Zertifikat (Platin/Gold/Silber/Bronze) | DGNB Certification | Certificação DGNB | Certificación DGNB | Regulatory |
| 7 | LEED | LEED-Zertifizierung | LEED (Certified/Silver/Gold/Platinum) | Certificação LEED | Certificación LEED | Regulatory |
| 8 | BREEAM | BREEAM-Zertifizierung | BREEAM (Pass to Outstanding) | Certificação BREEAM | Certificación BREEAM | Regulatory |
| 9 | Fire Safety | **Brandschutzkonzept**; Brandschutznachweis | Fire Code/NFPA (US); Part B (UK); NCC (AU) | Normas de Segurança contra Incêndio | CTE-SI (Seguridad en caso de Incendio) | Regulatory |
| 10 | Site Safety Plan | **SiGe-Plan** (Sicherheits- und Gesundheitsschutzplan) | Site Safety Plan (US); Construction Phase Plan (UK); WHS Plan (AU) | **PCMAT** (Programa de Condições e Meio Ambiente de Trabalho) | Plan de Seguridad y Salud en el Trabajo | Regulatory |
| 11 | Building Code | **Bauordnung** (Landesbauordnung/LBO); **MBO** (Musterbauordnung) | IBC (US); Building Regulations (UK); NCC/BCA (AU) | **Código de Obras** (municipal) | Código Técnico de la Edificación (CTE) (ES) | Regulatory |
| 12 | Zoning | **Bebauungsplan (B-Plan)**; Flächennutzungsplan (F-Plan) | Zoning (US); Local Plan (UK); LEP (AU) | Plano Diretor; Zoneamento Urbano | Plan de Ordenamiento Territorial; Zonificación | Regulatory |
| 13 | Heritage Protection | **Denkmalschutz** | Historic Preservation (US); Listed Building (UK); Heritage Listing (AU) | **Tombamento** (IPHAN) | Protección del Patrimonio Histórico; BIC | Regulatory |
| 14 | Acceptance / Handover | **Abnahme** (förmlich/fiktiv/stillschweigend) | Final Acceptance (US); Practical Completion (UK/AU) | Recebimento da Obra (provisório/definitivo) | Recepción de la Obra; Acta de Entrega-Recepción | Regulatory |
| 15 | Occupancy Permit | **Nutzungsgenehmigung** | Certificate of Occupancy (CO) (US); Occupation Certificate (AU) | **Habite-se** | Dictamen de Habitabilidad (MX); Certificado de Ocupación (CO) | Regulatory |

Switzerland uses distinct sustainability standards: **SNBS** (Standard Nachhaltiges Bauen Schweiz) and **Minergie** instead of DGNB. Austria uses **klimaaktiv** and **ÖGNB/TQB**. Brazil's construction-specific quality program **PBQP-H** (aligned with ISO 9001) is mandatory for accessing federal housing finance through Caixa Econômica Federal.

---

## Regional English variants that every localization team must know

These 20 US/UK/AU splits cause the most confusion in multilingual AEC platforms and contract translations.

| Concept | US English | UK English | Australian English |
|---------|-----------|-----------|-------------------|
| Contract modification | **Change Order** | **Variation** / Variation Order | **Variation** |
| Payment withheld | **Retainage** (5–10%) | **Retention** (5%) | **Retention** |
| Defects list at completion | **Punch List** | **Snag List** | **Defects List** |
| Primary contractor | **General Contractor (GC)** | **Main Contractor** / Principal Contractor | **Head Contractor** |
| Project owner | **Owner** | **Client / Employer** | **Principal** |
| Payment request | **Pay Application** (AIA G702) | **Payment Certificate** / Interim Valuation | **Progress Claim** |
| Near-completion | **Substantial Completion** | **Practical Completion (PC)** | **Practical Completion (PC)** |
| Competitive pricing | **Bid / Bidding** | **Tender / Tendering** | **Tender / Tendering** |
| On-site supervisor | **Superintendent** (contractor rep) | **Clerk of Works** (client rep) | **Superintendent** (independent certifier) |
| Document submission | **Submittal** | **Shop Drawing** / Technical Submission | **Shop Drawing** |
| Wood material | **Lumber** | **Timber** | **Timber** |
| Interior wall board | **Drywall** / Sheetrock | **Plasterboard** | **Plasterboard** / Gyprock |
| Concrete mold | **Concrete Form** | **Formwork / Shuttering** | **Formwork** |
| Steel reinforcement | **Rebar** | **Reinforcement** | **Reo** (informal) |
| Construction timeline | **Schedule** | **Programme** | **Programme** |
| Cost professional | **Estimator / Cost Engineer** | **Quantity Surveyor (QS)** | **Quantity Surveyor (QS)** |

The Australian **Superintendent** role is particularly treacherous for translators — in the US it means the contractor's site manager, but in Australia under AS 4000 contracts, the Superintendent is an independent contract administrator (closer to the UK's Contract Administrator or Engineer under FIDIC).

---

## German-speaking market variants: DE vs. AT vs. CH

| Concept | Germany (DE) | Austria (AT) | Switzerland (CH) |
|---------|-------------|-------------|------------------|
| Standard contract terms | **VOB/B** (DIN 1961) | **ÖNORM B 2110** | **SIA 118** |
| Procurement rules | **VOB/A** | **ÖNORM A 2050** / BVergG | SIA + öff. Beschaffungsrecht |
| Fee regulations | **HOAI** (9 Leistungsphasen) | HOA (less formalized) | **SIA 102** (architects) / **SIA 103** (engineers) |
| Building permit | **Baugenehmigung** | **Baubewilligung** | **Baubewilligung** / Baugesuch |
| Zoning plan | **Bebauungsplan** | **Flächenwidmungsplan** | **Zonenplan** / BZR |
| Acceptance | **Abnahme** | **Übernahme** (deemed after 30 days) | **Abnahme** (per SIA 118) |
| Progress payment | **Abschlagszahlung** | Abschlagszahlung / Teilrechnung | **Akontozahlung** |
| Warranty period | **4 years** (VOB/B) / **5 years** (BGB) | **3 years** (ÖNORM/ABGB) | **5 years** (OR); SIA-specific rules |
| Standards body | **DIN** | **Austrian Standards Int'l** | **SNV** / **SIA** (construction) |
| Sustainability cert. | **DGNB** / BNB | **klimaaktiv** / ÖGNB / TQB | **SNBS** / **Minergie** |
| Tender/bid (verb) | Ausschreibung | Ausschreibung | **Submission** |
| Trades (colloquial) | Handwerker / Gewerke | **Professionisten** | Handwerker / Unternehmer |
| Site supervision | Bauleitung / Objektüberwachung (HOAI LP8) | **Örtliche Bauaufsicht (ÖBA)** | Bauleitung (per SIA) |

Swiss construction's use of **"Submission"** for the tendering/bidding process is a notable false friend — in Germany, "Submission" is rarely used this way. The **SIA norms** (Schweizerischer Ingenieur- und Architektenverein) function as Switzerland's complete alternative to Germany's VOB/HOAI system, with SIA 112 defining project phases quite differently from HOAI's nine Leistungsphasen.

---

## Brazilian construction market: a self-contained terminology ecosystem

Brazil has developed perhaps the most distinct national construction terminology of any major market, anchored in three pillars: **SINAPI** (cost indices), **BDI** (markup structure), and **ABNT** (technical norms).

**SINAPI** (Sistema Nacional de Pesquisa de Custos e Índices da Construção Civil) is the mandatory cost reference for all Brazilian public works since 2003. Produced jointly by IBGE and Caixa Econômica Federal, it publishes monthly reference prices for **8,500+** unit cost compositions covering materials, labor, and equipment. Private sector projects commonly use **TCPO** (Tabela de Composições de Preços para Orçamentos, published by PINI since 1955) as a complement.

**BDI** (Benefícios e Despesas Indiretas) is Brazil's unique markup methodology. Unlike a simple overhead-and-profit percentage, BDI is a formula-derived markup incorporating central administration (~4–7%), insurance (~0.36%), risk (~0.53%), financial costs (~1%), taxes (COFINS 3% + PIS 0.65% + ISS ~3%), and profit (~6.6–10%). The **TCU** (Federal Court of Accounts) regulates reference BDI ranges via Acórdão 2622/2013, typically **20–30%** for standard construction. The formula is: BDI = [(1+AC+SG+R) × (1+DF) × (1+L) / (1−I)] − 1.

Key Brazilian-specific terms with no direct international equivalents:

- **Habite-se**: Municipal occupancy permit certifying compliance with approved plans — a uniquely Brazilian administrative instrument
- **ART/RRT**: Mandatory professional responsibility registrations (ART for engineers via CREA; RRT for architects via CAU) that legally bind the professional to every project
- **CUB** (Custo Unitário Básico): Monthly per-m² construction cost index calculated by each state's Sinduscon per NBR 12721, used as a benchmark for real estate contracts
- **Licitação modalities** under Lei 14.133/2021: Pregão (reverse auction), Concorrência (open competitive), Concurso (design competition), Leilão (auction), Diálogo Competitivo (competitive dialogue)
- **Empreitada types**: por preço unitário (unit price), por preço global (lump sum), integral (turnkey), contratação integrada (design-build), contratação semi-integrada (modified design-build)

---

## Latin American Spanish: where Mexico, Colombia, and Chile diverge

Latin American construction Spanish varies significantly by country, particularly in procurement and measurement terminology.

| Concept | Mexico | Colombia | Chile | Spain |
|---------|--------|----------|-------|-------|
| Bill of Quantities | **Catálogo de Conceptos** | Presupuesto de Obra | Presupuesto de Obra | Presupuesto; Cuadro de Precios |
| Unit Price Analysis | **APU** | **APU** | **APU** | Descompuesto de Precios |
| Progress Billing | **Estimación de Obra** | **Acta de Avance** | **Estado de Pago** | Certificación de Obra |
| Quantity Take-Off | **Generador de Obra** | Acta de Medición | **Cubicación** | Medición |
| Site Diary | **Bitácora de Obra** | Bitácora de Obra | **Libro de Obra** | Libro de Órdenes |
| Lump Sum | **Precio Alzado** | Precio Global Fijo | **Suma Alzada** | Precio Alzado / Tanto Alzado |
| Performance Bond | **Fianza de Cumplimiento** | **Póliza de Cumplimiento** | **Boleta de Garantía** | Garantía de Cumplimiento |
| Building Permit | **Licencia de Construcción** | **Licencia de Construcción** | **Permiso de Edificación** | Licencia de Obras |
| Handover | **Acta de Entrega-Recepción** | Acta de Entrega | **Acta de Recepción** | Acta de Recepción |
| Building Code | **NOM/NMX** standards | **NSR-10** (seismic focus) | **NCh** standards + **OGUC** | **CTE** |
| Cost Index | INPC construcción / BIMSA | ICCV (DANE) | ICE (INE) | Índice de Costes de Construcción |
| Occupancy Permit | **Dictamen de Habitabilidad** | **Certificado de Ocupación** | **Recepción Municipal** | Licencia de Primera Ocupación |

Mexico's **Generador de Obra** — the detailed measurement record that supports progress payment claims — has no equivalent single term in other Spanish-speaking markets. Colombia's unique **Curadurías Urbanas** (private entities authorized to issue building permits) and **NSR-10** seismic code (with 11 titles A–K) reflect its specific regulatory architecture. Chile's construction market uses terminology closer to European Spanish than Mexico does, with **cubicación** (cubing/volumetric measurement) preferred over Mexico's generador.

---

## How major AEC platforms localize their terminology

Platform localization reveals which terms the industry is actually standardizing around, as opposed to theoretical translations.

| Platform | Origin | Languages | Key localization patterns |
|----------|--------|-----------|--------------------------|
| **Procore** | US | 15 localizations (EN-US/UK/AU, DE, ES-419, ES-ES, PT-BR, FR, PL, JA, ZH) | Offers "Point-of-View Dictionaries" (GC, Owner, Specialty Contractor) that rename tools. DE: Nachtragsauftrag, Mängelliste, Bautagebuch |
| **Autodesk ACC** | US | 14+ languages | DE: Kollisionsprüfung, Modellkoordination, Mengenermittlung. Construction IQ brand name preserved across all localizations |
| **RIB iTWO / RIB 4.0** | DE (now Schneider Electric) | DE primary, EN, international | Native German: LV, Aufmaß, Vergabe, GAEB, Kalkulation. Full **AVA process** (Ausschreibung-Vergabe-Abrechnung) embedded. ÖNORM support for AT market |
| **NEVARIS** | DE/AT | DE primary | Products: NEVARIS Build, Success X (AVA for AT). Uses **123erfasst** app for mobile Bautagebuch/Mängelmanagement |
| **BRZ** | DE | DE primary | First DACH platform with embedded **KI-Kalkulation** (AI estimating). Mengenermittlung frei und REB. Baulohn (construction payroll) specialty |
| **PlanRadar** | AT | 15+ languages | Core: **Mängelmanagement** (defect management), Bautagebuch, plan-based defect marking. Mobile-first field documentation |
| **Oracle Aconex** | AU (now Oracle) | 14 languages (AR, DE, EN, FR, IT, JA, KO, PL, PT, RU, ES, TR, ZH) | Focuses on document register, transmittal, audit trail terminology. Integrates with Primavera for schedule/cost |
| **Trimble** | US | 15+ (Tekla Structures) | Branded concept: "Constructible BIM." DE: Bewehrung, Stahlbau, Schalungsplanung. ViewpointOne for ERP integration |

The fundamental split in AEC platform terminology follows a geographic fault line: **Anglo-American platforms** (Procore, ACC, Aconex) are built around RFI/submittal/change order workflows, while **DACH platforms** (RIB, NEVARIS, BRZ) are structured around the **AVA** lifecycle (Ausschreibung → Vergabe → Abrechnung) and **GAEB** data exchange. These represent genuinely different mental models for construction project delivery, not merely different words for the same thing.

---

## Conclusion: Three insights for building multilingual AEC systems

First, **never assume one-to-one translation exists**. The German Aufmaß, Brazilian BDI, and Mexican Generador de Obra each represent concepts that have no precise equivalent in other languages — they encode specific legal and procedural contexts that a simple glossary entry cannot capture. Any AEC platform localization must go beyond word substitution to adapt workflows.

Second, **BIM terminology is converging faster than ERP terminology**. The buildingSMART-driven standardization of IFC, BCF, CDE, and ISO 19650 concepts means BIM vocabulary is broadly consistent across languages (with English acronyms preserved globally). By contrast, construction ERP and procurement terms remain deeply fragmented because they are anchored in national legal frameworks — VOB, FIDIC, NEC, AIA, Lei 14.133 — that show no signs of harmonization.

Third, **regional variants within a single language matter as much as cross-language differences**. The US/UK/AU English splits (Change Order vs. Variation vs. Variation; Retainage vs. Retention; Punch List vs. Snag List vs. Defects List) and the DE/AT/CH splits (VOB vs. ÖNORM vs. SIA; Abnahme vs. Übernahme; 4-year vs. 3-year vs. 5-year warranty) create as many localization challenges as translating between entirely different languages. AEC platforms serving global markets must implement not just language selection but **regional variant selection** within each language.