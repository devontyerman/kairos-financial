// Carrier product data, derived from the source guide.
// Notes paraphrased from the original; URLs preserved verbatim.
// Display order is the order of this array — drag-to-reorder removed.

const PRODUCTS = [
  // ============ WHOLE LIFE ============

  {
    id: "aetna-cva-accendo",
    tone: "green",
    cat: "wl",
    carrier: "Aetna CVS",
    name: "Accendo",
    rec: "niche",
    badges: ["Simplified issue", "Level / graded"],
    note: [
      "First choice for whole life clients. Two different rate classes to capture majority of clients.",
      "Competitive rates and a recognizable brand — solid alternative when a client doesn't fit the primary recommended carriers."
    ],
    bestFor: "First choice for whole life clients. Two different rate classes to capture majority of clients.",
    risk: "Health-tiered benefit",
    coverage: "",
    ageRange: "",
    method: "",
    timeline: "",
    links: [
      { kind: "uw", label: "Underwriting Guide", href: "https://www.amhomelife.com/images/Underwriting-PSFE-Disease_Guide.pdf" }
    ]
  },
  {
    id: "transamerica-fe",
    tone: "green",
    cat: "wl",
    carrier: "Transamerica",
    name: "FE Express",
    rec: "rec",
    feat: true,
    badges: ["Near-true comp", "Instant answer", "6-digit text code", "Accepts CHF"],
    note: [
      "Good for unhealthy people, very lenient with heart conditions, CHF, COPD, and other various health conditions. ",
      "Direct payments work from Social Security Direct Express, credit card, or debit card.",
      { type: "warn", text: "Avoid card payments where possible — chargeback risk on lapses is significantly higher." }
    ],
    bestFor: "Good for unhealthy people, very lenient with heart conditions, CHF, COPD, and other various health conditions.",
    risk: "Low",
    coverage: "",
    ageRange: "",
    method: "",
    timeline: "",
    links: [
      { kind: "uw", label: "Underwriting Guide", href: "https://drive.google.com/file/d/1Jsy8VLMKONVCHzUJMGrJIIyqVfYN6VeY/view?usp=sharing" }
    ]
  },
  {
    id: "corebridge-siwl",
    tone: "green",
    cat: "wl",
    carrier: "Corebridge",
    name: "Simplified Issue Whole Life",
    rec: "niche",
    badges: ["Simplified issue", "Day-1 coverage", "Few health questions"],
    note: [
      "A bit more lenient with cancer cases, however requires full electronic signature so not the first choice.",
      "Try this before guaranteed issue: a healthy-enough client gets immediate full coverage instead of a graded benefit."
    ],
    bestFor: "A bit more lenient with cancer cases, however requires full electronic signature so not the first choice.",
    risk: "Health questions apply",
    coverage: "",
    ageRange: "",
    method: "",
    timeline: "",
    links: [
      { kind: "uw", label: "Underwriting Guide", href: "https://drive.google.com/file/d/10k4FhPc5s8iuY9onfwK4_ZgLDw5SGXmQ/view?usp=sharing" }
    ]
  },
  {
    id: "moo-living-promise",
    tone: "green",
    cat: "wl",
    carrier: "Mutual of Omaha",
    name: "Living Promise",
    rec: "rec",
    feat: true,
    badges: ["Friendly w/ anxiety & depression", "6-digit text code"],
    note: [
      "Competitively priced but lower compensation and stricter underwriting, only use for a healthier clients and when the price is significantly cheaper.",
      "Strong fallback when someone was declined for a mental-health condition specifically and is too price-sensitive for Transamerica."
    ],
    bestFor: "Competitively priced but lower compensation and stricter underwriting, only use for a healthier clients and when the price is significantly cheaper.",
    risk: "Low",
    coverage: "",
    ageRange: "",
    method: "",
    timeline: "",
    links: [
      { kind: "uw", label: "Underwriting Guide", href: "https://drive.google.com/file/d/1PBr_RlB17x7f90c0mLGtHi_yYNPtOp_R/view?usp=sharing" }
    ]
  },
  {
    id: "amam-family-senior",
    tone: "gray",
    cat: "wl",
    carrier: "American Amicable",
    name: "Family Choice / Senior Choice",
    rec: "niche",
    badges: ["Voice signature", "0–49 / 50–85", "ROP graded"],
    note: [
      { type: "info", text: "Unique: the client can sign by voice — call in on a recorded line and read the script. Perfect when there's no cell phone, no email, or DocuSign keeps failing." },
      "Only carrier with voice signature if the client does not have a cell phone or computer. Approval can take a while for some cases and compensation is lower so not recommended unless your client is unable to receive a text or do an electronic signature. ",
      "Never lose a deal to DocuSign issues with this product in your pocket."
    ],
    bestFor: "Only carrier with voice signature if the client does not have a cell phone or computer. Approval can take a while for some cases and compensation is lower so not recommended unless your client is unable to receive a text or do an electronic signature.",
    risk: "Low",
    coverage: "",
    ageRange: "",
    method: "",
    timeline: "",
    links: [
      { kind: "uw", label: "Senior Choice UW Guide", href: "https://drive.google.com/file/d/1mDebIlL3ErZngisZyHiUSYwlGHaRKS_w/view?usp=sharing" },
      { kind: "uw", label: "Family Choice UW Guide", href: "https://drive.google.com/file/d/12kUHnrL3TaDShymuCH90AW0qjUrf7IDJ/view?usp=sharing" }
    ]
  },
  {
    id: "ethos-trustage-siwl",
    tone: "red",
    cat: "wl",
    carrier: "Ethos / TruStage",
    name: "TruStage SIWL",
    rec: "rec",
    feat: true,
    badges: ["6-digit text code", "Reduced comp <60 / >80", "Watch GI flag"],
    note: [
      "Very lenient underwriting however lower compensation and 6 month full chargeback rule. Only recommended as a last resort before going to guaranteed issue. Keep in mine compensation will also be reduced by around 50% for clients younger than 60 or older than 80.  ",
      { type: "warn", text: "If approval comes back tagged Guaranteed Issue, that product pays only 2.5% commission. Pivot to Corebridge GI if no other option works." },
      "Clients under 60 and over 80 pay a significantly reduced commission."
    ],
    bestFor: "Mid-age, healthy",
    risk: "Comp cliff <60 / >80",
    coverage: "",
    ageRange: "",
    method: "",
    timeline: "",
    links: [
      { kind: "uw", label: "Underwriting Guide", href: "https://online.flippingbook.com/view/881422400/2/" }
    ]
  },
  {
    id: "corebridge-giwl",
    tone: "red",
    cat: "wl",
    carrier: "Corebridge",
    name: "Guaranteed Issue Whole Life",
    rec: "skip",
    badges: ["Guaranteed issue", "No health questions", "Graded years 1–2"],
    note: [
      "Guaranteed issue — no health questions and no medical exam. Nobody is declined. Compensation is 50% lower, and it has a 2 year waiting period for coverage to start. If client dies within 2 years all commission is charged back. This is a last resort option. Accidental may be a better fit.",
      "The fallback when a client can't qualify anywhere else. Reach for this before settling for a graded product that pays less.",
      { type: "warn", text: "Graded death benefit in years 1–2 (return of premium plus interest). Full face amount applies for accidental death." }
    ],
    bestFor: "Uninsurable clients",
    risk: "Graded years 1–2",
    coverage: "",
    ageRange: "",
    method: "",
    timeline: "",
    links: []
  },

  // ============ IUL ============

  {
    id: "amam-intelligent-choice",
    tone: "green",
    cat: "iul",
    carrier: "American Amicable",
    name: "Intelligent Choice",
    rec: "niche",
    badges: ["No medical exam", "Not instant"],
    note: [
      "Can be more lenient than other options with slightly longer approval timelines.  ",
      "No medical exams — but not instant approval, so plan for some wait time."
    ],
    bestFor: "Can be more lenient than other options with slightly longer approval timelines.  ",
    risk: "Slower",
    coverage: "",
    ageRange: "",
    method: "",
    timeline: "",
    links: [
      { kind: "uw", label: "Underwriting Guide", href: "https://drive.google.com/file/d/1qA9AmxUYpDG_XBUcHeoHXLG2XmsZ-C7m/view?usp=sharing" },
      { kind: "pg", label: "Product Guide", href: "https://drive.google.com/file/d/1xmlbiE76N-cSjR216tBLs4BMX0xTb2O7/view?usp=sharing" }
    ]
  },
  {
    id: "moo-iul-express",
    tone: "green",
    cat: "iul",
    carrier: "Mutual of Omaha",
    name: "Indexed Universal Life Express",
    rec: "niche",
    badges: ["Simplified issue", "No medical exam"],
    note: [
      "Best go to for higher coverage limits and permanent style coverage for younger healthy clients. Not meant for maximizing cash value. ",
      "If the client's primarily focused on the insurance side of an IUL, there are quicker options."
    ],
    bestFor: "Best go to for higher coverage limits and permanent style coverage for younger healthy clients. Not meant for maximizing cash value. ",
    risk: "Low",
    coverage: "",
    ageRange: "",
    method: "",
    timeline: "",
    links: [
      { kind: "uw", label: "Underwriting Guide", href: "https://drive.google.com/file/d/1KjXSTyJlmvtk6Jl2475b0xL17xal7vfB/view?usp=drive_link" },
      { kind: "pg", label: "Product Guide", href: "https://drive.google.com/file/d/1zAVI9Hv-ExPqzovS0pOpW1MuHjZrX27g/view?usp=drive_link" }
    ]
  },
  {
    id: "ethos-iul",
    tone: "gray",
    cat: "iul",
    carrier: "Ethos",
    name: "Ethos IUL",
    rec: "rec",
    feat: true,
    badges: ["No medical exam", "90% instant", "Higher young limits"],
    note: [
      "Solid IUL option for younger healthy people with a 90% instant approval rate",
      "A little stricter than the other options, but has higher limits for younger clients."
    ],
    bestFor: "Solid IUL option for younger healthy people with a 90% instant approval rate if Mutual of Omaha's IUL rates are not competitive enough.",
    risk: "Stricter",
    coverage: "",
    ageRange: "",
    method: "",
    timeline: "",
    links: [
      { kind: "pg", label: "Product Guide", href: "https://online.flippingbook.com/view/319418901/4" },
      { kind: "kc", label: "Knockout Conditions", href: "https://online.flippingbook.com/view/318795893/" },
      { kind: "vid", label: "IUL Training Video", href: "https://vimeo.com/914854733/b8671a27a3" }
    ]
  },

  // ============ TERM ============

  {
    id: "instabrain-term",
    tone: "green",
    cat: "term",
    carrier: "InstaBrain",
    name: "Term — Living Benefits & Pure Term",
    rec: "rec",
    feat: true,
    badges: ["Instant decision", "Easy application", "Young & healthy"],
    note: [
      "Best for young, healthy clients. Instant decision and an easy application — two products under one roof.",
      { type: "info", text: "<b>InstaBrain Term With Living Benefits</b> · $50,000–$1,000,000 · Ages 18–60 · Includes Chronic Illness & Terminal Illness Riders." },
      { type: "info", text: "<b>InstaBrain Pure Term</b> · $50,000–$1,000,000 · Ages 18–60 · Whole Life Conversion Option." }
    ],
    bestFor: "Best for young, healthy clients. Instant decision and an easy application — two products under one roof.",
    risk: "Low",
    coverage: "",
    ageRange: "",
    method: "",
    timeline: "",
    links: [
      { kind: "rg", label: "Running Guide", href: "https://drive.google.com/file/d/16tVnf0XyaVVXEJwej3g-7PuDT2L-l2QN/view?usp=sharing" }
    ]
  },
  {
    id: "moo-term-express",
    tone: "green",
    cat: "term",
    carrier: "Mutual of Omaha",
    name: "Term Life Express",
    rec: "niche",
    badges: ["Name recognition", "More lenient"],
    note: [
      "Solid simplified issue term that never requires full medical underwriting, can be more lenient that most other options.",
      "Better options exist for healthy clients, but this can be slightly more lenient if your client is on the edge of approval elsewhere."
    ],
    bestFor: "Solid simplified issue term that never requires full medical underwriting ",
    risk: "Low",
    coverage: "",
    ageRange: "",
    method: "",
    timeline: "",
    links: [
      { kind: "uw", label: "Underwriting Guide", href: "https://drive.google.com/file/d/1KjXSTyJlmvtk6Jl2475b0xL17xal7vfB/view?usp=sharing" },
      { kind: "pg", label: "Product Guide", href: "https://drive.google.com/file/d/1zAVI9Hv-ExPqzovS0pOpW1MuHjZrX27g/view?usp=sharing" }
    ]
  },
  {
    id: "amam-term-made-simple",
    tone: "gray",
    cat: "term",
    carrier: "American Amicable",
    name: "Term Made Simple",
    rec: "rec",
    feat: true,
    badges: ["Competitive 60+", "Healthy clients"],
    note: [
      "Solid option with competitive rates — especially for clients over 60 who want term and are healthy."
    ],
    bestFor: "Solid option with competitive rates — especially for clients over 60 who want term and are healthy.",
    risk: "Low",
    coverage: "",
    ageRange: "",
    method: "",
    timeline: "",
    links: [
      { kind: "pg", label: "Product Guide", href: "https://drive.google.com/file/d/1jWDkKrY1U4KyI3zeVAVLsqLQp2bajs6-/view?usp=sharing" },
      { kind: "uw", label: "Underwriting Guide", href: "https://drive.google.com/file/d/1cAjRUy1NunwFFhl6mq67NA7Nh5iHg0B1/view?usp=sharing" }
    ]
  },
  {
    id: "ethos-term",
    tone: "gray",
    cat: "term",
    carrier: "Ethos",
    name: "Term Life",
    rec: "rec",
    feat: true,
    badges: ["No medical exam", "90% instant"],
    note: [
      "No medical exams. ~90% of applications return an instant answer."
    ],
    bestFor: "No medical exams. ~90% of applications return an instant answer.",
    risk: "Low",
    coverage: "",
    ageRange: "",
    method: "",
    timeline: "",
    links: [
      { kind: "kc", label: "Knockout Conditions", href: "https://online.flippingbook.com/view/266827897/2" }
    ]
  },
  {
    id: "transamerica-trendsetter",
    tone: "red",
    cat: "term",
    carrier: "Transamerica",
    name: "Trendsetter & Trendsetter LB",
    rec: "pro",
    badges: ["Cheapest term", "Strictest UW", "Case-by-case face"],
    note: [
      "Cheapest term option out there — and the most strict on underwriting. Approvals can take 2-4 weeks, and low commission, Use as a last resort to beat price or get edge cases approved. ",
      { type: "warn", text: "High likelihood of full medical exams and a full doctor's statement, which increases denial risk and delays both client coverage and your commission. Only use if you have to come in cheaper, AND you're confident in the client's medical history cross-referenced against the UW guide." },
      "Coverage amount has no fixed limit — case by case."
    ],
    bestFor: "Cheapest term option out there — and the most strict on underwriting. Approvals can take 2-4 weeks, and low commission, Use as a last resort to beat price or get edge cases approved. ",
    risk: "Full med exam likely",
    coverage: "",
    ageRange: "",
    method: "",
    timeline: "",
    links: [
      { kind: "uw", label: "Underwriting Guide", href: "https://drive.google.com/file/d/1ZZlmjmCHesffbOS6lOHP4wtDFku-1CEA/view?usp=sharing" },
      { kind: "kc", label: "Common Conditions", href: "https://drive.google.com/file/d/1P0VOmPN-eT6wpLDYd4DhkFNCPhl1Z-9E/view?usp=sharing" }
    ]
  },

  // ============ ACCIDENTAL ============
  {
    id: "accidental-coverage",
    tone: "green",
    cat: "acc",
    carrier: "Americo / Mutual of Omaha",
    name: "Accidental Coverage",
    rec: "niche",
    badges: ["Guaranteed issue", "No health questions", "Accident-only"],
    note: [
      "Accident-only coverage — guaranteed issue with no health questions. Pays a benefit for death or injury resulting from a covered accident. Do Guaranteed Advantage with Mutual of Omaha if you have your 215 or do ADB with Americo if you do not.",
      "Useful add-on or fallback for clients who can't qualify for life coverage, or who want extra protection on top of an existing policy."
    ],
    bestFor: "Uninsurable / add-on",
    risk: "Accident-only — no natural causes",
    coverage: "",
    ageRange: "",
    method: "",
    timeline: "",
    links: []
  }
];

const CATEGORIES = [
  { id: "wl",   name: "Whole Life", short:"WL",  desc: "Permanent coverage that never expires as long as premiums are paid. Builds cash value." },
  { id: "iul",  name: "Indexed UL", short:"IUL", desc: "Permanent coverage with cash value tied to a market index — flexible premiums, upside with floors." },
  { id: "term", name: "Term Life",  short:"TERM",desc: "Pure protection for a fixed period. Lowest premiums, no cash value, expires." },
  { id: "acc",  name: "Accidental",  short:"ACC", desc: "Accident-only coverage. Guaranteed issue, no health questions — pays on covered accidents." }
];

window.PRODUCTS = PRODUCTS;
window.CATEGORIES = CATEGORIES;
