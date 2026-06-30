const { useState, useMemo, useEffect, useCallback } = React;

const STATUS_LABEL = {
  rec: "Recommended",
  niche: "Situational",
  pro: "Pro · strict",
  skip: "Last resort"
};

const LINK_KIND = {
  uw: "UW",
  pg: "PG",
  kc: "KC",
  vid: "VID",
  rg: "RG"
};

// Derive a 1-line summary from the first string note (or first pull-quote text).
function summaryOf(p) {
  for (const n of p.note) {
    if (typeof n === "string") {
      return n.replace(/<[^>]+>/g, "");
    }
  }
  const pull = p.note.find((n) => typeof n === "object");
  return pull ? pull.text.replace(/<[^>]+>/g, "") : "";
}

function NoteBlock({ items }) {
  return (
    <div className="note">
      {items.map((it, i) => {
        if (typeof it === "string") {
          return <p key={i} dangerouslySetInnerHTML={{ __html: it }}>
</p>;}
        const cls = it.type === "warn" ? "p-warn" : it.type === "info" ? "p-info" : "";
        return <div key={i} className={`pull ${cls}`} dangerouslySetInnerHTML={{ __html: it.text }} />;
      })}
    </div>);

}

function Row({ p, open, onToggle }) {
  const summary = useMemo(() => summaryOf(p), [p]);

  return (
    <div
      className="row"
      data-rec={p.rec}
      data-tone={p.tone}
      data-open={open ? "true" : "false"}
      id={p.id}>
      <button className="row-head" onClick={() => onToggle(p.id)} aria-expanded={open}>
        <span className="status-bar" aria-hidden />
        <span className="row-main">
          <span className="row-title">
            <span className="row-carrier">{p.carrier}</span>
            <span className="row-name">{p.name}</span>
          </span>
          <span className="row-summary">{summary}</span>
        </span>
        <span className="row-meta">
          <span className="chevron" aria-hidden>
            <svg width="14" height="14" viewBox="0 0 14 14" fill="none">
              <path d="M3 5.5L7 9.5L11 5.5" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" strokeLinejoin="round" />
            </svg>
          </span>
        </span>
      </button>

      <div className="row-body">
        <div className="row-body-inner">
          <div className="body-right">
            <div className="meta-grid">
              <div className="meta-row">
                <div className="k">Description</div>
                <div className="v">{p.bestFor || <span className="placeholder">Solid simplified issue term that never requires full medical underwriting, can be more lenient that most other options.</span>}</div>
              </div>
              <div className="meta-row">
                <div className="k">Method of application</div>
                <div className="v">{p.method || <span className="placeholder">Text code</span>}</div>
              </div>
              <div className="meta-row">
                <div className="k">Underwriting timeline</div>
                <div className="v">{p.timeline || <span className="placeholder">Fully medically underwritten, smaller amounts can be accelerated underwriting depending on age</span>}</div>
              </div>
            </div>
            {p.links.length > 0 &&
            <div className="links">
                {p.links.map((l, i) =>
              <a key={i} className="lnk" href={l.href} target="_blank" rel="noopener noreferrer">
                    <span className="kind">{LINK_KIND[l.kind]}</span>
                    <span>{l.label}</span>
                    <span className="arrow">↗</span>
                  </a>
              )}
              </div>
            }
          </div>
        </div>
      </div>
    </div>);

}

// Read the parent site's theme (same key the Sales Hub bootstrap uses).
function readSiteTheme() {
  try {
    const v = localStorage.getItem("kf_skin_theme_v1");
    if (v === "dark" || v === "light") return v;
  } catch (e) {}
  return "dark"; // matches the Sales Hub default
}

function App() {
  const [filter, setFilter] = useState("all");
  const [q, setQ] = useState("");
  const [openIds, setOpenIds] = useState(new Set());

  const [theme, setTheme] = useState(readSiteTheme);

  useEffect(() => {
    document.documentElement.setAttribute("data-theme", theme);
  }, [theme]);

  // Follow the parent site's theme — fires when the Sales Hub toggle flips it.
  useEffect(() => {
    const onStorage = (e) => {
      if (e.key !== "kf_skin_theme_v1") return;
      if (e.newValue === "dark" || e.newValue === "light") setTheme(e.newValue);
    };
    window.addEventListener("storage", onStorage);
    return () => window.removeEventListener("storage", onStorage);
  }, []);

  const toggleRow = useCallback((id) => {
    setOpenIds((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);else next.add(id);
      return next;
    });
  }, []);

  const counts = useMemo(() => {
    const c = { all: PRODUCTS.length };
    CATEGORIES.forEach((cat) => {c[cat.id] = PRODUCTS.filter((p) => p.cat === cat.id).length;});
    return c;
  }, []);

  const filtered = useMemo(() => {
    const ql = q.trim().toLowerCase();
    return PRODUCTS.filter((p) => {
      if (filter !== "all" && p.cat !== filter) return false;
      if (!ql) return true;
      const blob = (p.name + " " + p.carrier + " " + p.badges.join(" ") + " " + (p.bestFor || "") + " " + p.note.map((n) => typeof n === "string" ? n : n.text).join(" ")).toLowerCase();
      return blob.includes(ql);
    });
  }, [filter, q]);

  // Group by category — display order is the order of PRODUCTS in data.jsx.
  const byCat = useMemo(() => {
    const out = {};
    CATEGORIES.forEach((c) => out[c.id] = []);
    filtered.forEach((p) => out[p.cat].push(p));
    return out;
  }, [filtered]);

  // ⌘K to focus search
  useEffect(() => {
    const onKey = (e) => {
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === "k") {
        e.preventDefault();
        document.getElementById("searchbox")?.focus();
      }
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, []);

  return (
    <>
      <header className="top">
        <div className="top-row">
          <div className="wordmark">Products<span className="dot">.</span></div>
          <div className="spacer" />
          <label className="search">
            <span className="glyph">⌕</span>
            <input
              id="searchbox"
              placeholder="Search carrier, product, condition…"
              value={q}
              onChange={(e) => setQ(e.target.value)} />

            <span className="kbd">⌘K</span>
          </label>
        </div>
        <div className="filter-row">
          <button className="pill" data-active={filter === "all"} onClick={() => setFilter("all")}>
            All <span className="count">{counts.all}</span>
          </button>
          {CATEGORIES.map((cat) =>
          <button key={cat.id} className="pill" data-active={filter === cat.id} onClick={() => setFilter(cat.id)}>
              {cat.name} <span className="count">{counts[cat.id]}</span>
            </button>
          )}
        </div>
      </header>

      <section className="lead">
        <div className="lead-text">
          <h1>Pick the <em>right</em> carrier.</h1>
          <p>Every product, sorted by how often you'll reach for it. Tap a row for notes, what it's best for, and the underwriting guide.</p>
        </div>
        <a
          className="master-cta"
          href="https://docs.google.com/spreadsheets/d/1JcF0HRDfgr2ScqXAPMDUOibEyTxb045CjymGLsQpJC0/edit?usp=sharing"
          target="_blank"
          rel="noopener noreferrer"
          title="Master Underwriting Guide (Google Sheets)">
          <span className="master-cta-label">Master UW Guide</span>
          <span className="master-cta-sub">All carriers · one sheet</span>
          <span className="master-cta-arrow">↗</span>
        </a>
      </section>

      {filtered.length === 0 &&
      <div className="empty">No products match "{q}". Try a different keyword.</div>
      }

      {CATEGORIES.map((cat) => {
        const items = byCat[cat.id];
        if (!items || items.length === 0) return null;
        return (
          <section className="section" key={cat.id} id={`sec-${cat.id}`}>
            <div className="sec-head">
              <h2>{cat.name}</h2>
              <span className="meta">{items.length} products</span>
              <span className="desc">{cat.desc}</span>
            </div>
            <div className="rows">
              {items.map((p) =>
              <Row
                key={p.id}
                p={p}
                open={openIds.has(p.id)}
                onToggle={toggleRow} />
              )}
            </div>
          </section>);

      })}

      <footer>
        <span>Internal field reference. Not for client distribution.</span>
        <span className="stamp">v2026.05</span>
      </footer>
    </>);

}

ReactDOM.createRoot(document.getElementById("root")).render(<App />);
