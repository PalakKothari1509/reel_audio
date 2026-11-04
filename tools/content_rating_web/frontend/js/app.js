/* Content Rating Tool — Main Application Controller */

const API_BASE = '';

const app = {
  ideas: [],
  ratings: [],
  selectedIdea: null,
  currentView: 'dashboard',

  async init() {
    this.setupNavigation();
    this.setupSearch();
    await this.loadIdeas();
    await this.loadRatings();
    this.renderDashboard();
    this.showToast('Content Rating Tool loaded. Offline mode ready.', 'info');
  },

  setupNavigation() {
    document.querySelectorAll('.nav-btn').forEach(btn => {
      btn.addEventListener('click', () => {
        const view = btn.getAttribute('data-view');
        this.navigateTo(view);
      });
    });
  },

  navigateTo(view) {
    this.currentView = view;
    document.querySelectorAll('.nav-btn').forEach(b => b.classList.remove('active'));
    document.querySelector(`[data-view="${view}"]`).classList.add('active');
    document.querySelectorAll('.view').forEach(v => v.classList.remove('active'));
    document.getElementById(`view-${view}`).classList.add('active');

    if (view === 'dashboard') this.renderDashboard();
    if (view === 'library') this.renderLibrary();
    if (view === 'export') this.renderExport();
  },

  setupSearch() {
    const search = document.getElementById('libSearch');
    search.addEventListener('input', () => this.renderLibrary());
    const cat = document.getElementById('libCategory');
    cat.addEventListener('change', () => this.renderLibrary());
    const verdict = document.getElementById('libVerdict');
    verdict.addEventListener('change', () => this.renderLibrary());
    const status = document.getElementById('libStatus');
    status.addEventListener('change', () => this.renderLibrary());
  },

  async loadIdeas() {
    try {
      const res = await fetch(`${API_BASE}/api/ideas`);
      const data = await res.json();
      this.ideas = data.ideas || [];
      this.populateCategoryFilter();
    } catch (e) {
      this.showToast('Failed to load ideas: ' + e.message, 'error');
    }
  },

  populateCategoryFilter() {
    const cats = [...new Set(this.ideas.map(i => i.category))].sort();
    const sel = document.getElementById('libCategory');
    cats.forEach(c => {
      const o = document.createElement('option');
      o.value = c;
      o.textContent = c;
      sel.appendChild(o);
    });
  },

  async loadRatings() {
    try {
      const res = await fetch(`${API_BASE}/api/ratings`);
      this.ratings = await res.json();
    } catch (e) {
      this.showToast('Failed to load ratings: ' + e.message, 'error');
    }
  },

  getRatingForIdea(ideaId) {
    return this.ratings.find(r => r.ideaId === ideaId);
  },

  renderDashboard() {
    const total = this.ideas.length;
    const evaluated = this.ratings.length;
    const ready = this.ratings.filter(r => r.verdict === 'Ready to Post').length;
    const minor = this.ratings.filter(r => r.verdict === 'Needs Minor Fixes').length;
    const major = this.ratings.filter(r => r.verdict === 'Needs Major Rewrite').length;
    const reject = this.ratings.filter(r => r.verdict === 'Reject').length;

    document.getElementById('statTotal').textContent = total;
    document.getElementById('statEvaluated').textContent = evaluated;
    document.getElementById('statReady').textContent = ready;
    document.getElementById('statMinor').textContent = minor;
    document.getElementById('statMajor').textContent = major;
    document.getElementById('statReject').textContent = reject;

    this.setupDashboardClickHandlers();
    this.renderDashboardRatingsTable();
  },

  setupDashboardClickHandlers() {
    // Total Ideas → clear all filters
    document.getElementById('statTotal').parentElement.onclick = () => {
      document.getElementById('libSearch').value = '';
      document.getElementById('libCategory').value = '';
      document.getElementById('libVerdict').value = '';
      document.getElementById('libStatus').value = '';
      this.navigateTo('library');
      this.renderLibrary();
    };

    // Evaluated → filter by evaluated status
    document.getElementById('statEvaluated').parentElement.onclick = () => {
      document.getElementById('libSearch').value = '';
      document.getElementById('libCategory').value = '';
      document.getElementById('libVerdict').value = '';
      document.getElementById('libStatus').value = 'evaluated';
      this.navigateTo('library');
      this.renderLibrary();
    };

    // Ready to Post → filter by verdict
    document.getElementById('statReady').parentElement.onclick = () => {
      document.getElementById('libSearch').value = '';
      document.getElementById('libCategory').value = '';
      document.getElementById('libVerdict').value = 'Ready to Post';
      document.getElementById('libStatus').value = '';
      this.navigateTo('library');
      this.renderLibrary();
    };

    // Needs Minor Fixes → filter by verdict
    document.getElementById('statMinor').parentElement.onclick = () => {
      document.getElementById('libSearch').value = '';
      document.getElementById('libCategory').value = '';
      document.getElementById('libVerdict').value = 'Needs Minor Fixes';
      document.getElementById('libStatus').value = '';
      this.navigateTo('library');
      this.renderLibrary();
    };

    // Needs Major Rewrite → filter by verdict
    document.getElementById('statMajor').parentElement.onclick = () => {
      document.getElementById('libSearch').value = '';
      document.getElementById('libCategory').value = '';
      document.getElementById('libVerdict').value = 'Needs Major Rewrite';
      document.getElementById('libStatus').value = '';
      this.navigateTo('library');
      this.renderLibrary();
    };

    // Reject → filter by verdict
    document.getElementById('statReject').parentElement.onclick = () => {
      document.getElementById('libSearch').value = '';
      document.getElementById('libCategory').value = '';
      document.getElementById('libVerdict').value = 'Reject';
      document.getElementById('libStatus').value = '';
      this.navigateTo('library');
      this.renderLibrary();
    };
  },

  renderDashboardRatingsTable() {
    const tableHead = document.getElementById('allIdeasTableHead');
    const tableBody = document.getElementById('allIdeasTableBody');
    const description = document.getElementById('allIdeasTableDescription');
    if (!tableHead || !tableBody || !description) return;
    const columns = this.getFullTableColumns();
    const rows = this.getAllIdeaRows();

    description.textContent = `${rows.length} ideas · ${this.ratings.length} evaluated · Expand cell details to read full text.`;
    tableHead.innerHTML = `<tr>${columns.map(column => `<th>${this.escapeHtml(column.label)}</th>`).join('')}</tr>`;
    tableBody.innerHTML = rows.map(({ idea, rating }) => `<tr>${columns.map(column => {
      const value = column.value(idea, rating);
      if (column.expandable && value) {
        const text = typeof value === 'string' ? value : JSON.stringify(value, null, 2);
        return `<td class="full-data-cell"><details><summary>View (${text.length} chars)</summary><pre>${this.escapeHtml(text)}</pre></details></td>`;
      }
      return `<td>${this.escapeHtml(value == null ? '' : String(value))}</td>`;
    }).join('')}</tr>`).join('');
  },

  getAllIdeaRows() {
    const ratingsById = new Map(this.ratings.map(rating => [rating.ideaId, rating]));
    return [...this.ideas]
      .sort((a, b) => a.id.localeCompare(b.id, undefined, { numeric: true }))
      .map(idea => ({ idea, rating: ratingsById.get(idea.id) || null }));
  },

  getFullTableColumns() {
    const columns = [
      { key: 'ideaId', label: 'Idea ID', value: idea => idea.id },
      { key: 'title', label: 'Title', value: idea => idea.title },
      { key: 'category', label: 'Category', value: idea => idea.category },
      { key: 'evaluationStatus', label: 'Evaluation Status', value: (_idea, rating) => rating ? 'Evaluated' : 'Not evaluated' },
      { key: 'overallScore', label: 'Overall Score', value: (_idea, rating) => rating?.overallScore },
      { key: 'rawScore', label: 'Raw Score', value: (_idea, rating) => rating?.rawScore },
      { key: 'verdict', label: 'Verdict', value: (_idea, rating) => rating?.verdict },
      { key: 'scoreCapped', label: 'Score Capped', value: (_idea, rating) => rating ? rating.scoreCapped : '' },
    ];

    const dimensionIds = [
      'hookStrength', 'relatability', 'storyStructure', 'ageAppropriateness',
      'hinglishNaturalness', 'characterConsistency', 'visualFeasibility',
      'soundOffReadability', 'engagementPotential', 'brandAndSafety',
    ];
    dimensionIds.forEach(id => {
      columns.push({
        key: `${id}_score`,
        label: `${id} Score`,
        value: (_idea, rating) => rating?.dimensionScores?.find(dimension => dimension.id === id)?.score,
      });
    });

    columns.push(
      { key: 'opening', label: 'Opening', value: idea => idea.opening, expandable: true },
      { key: 'problem', label: 'Problem', value: idea => idea.problem, expandable: true },
      { key: 'lesson', label: 'Lesson', value: idea => idea.lesson, expandable: true },
      { key: 'storyDetail', label: 'Story Detail', value: idea => idea.storyDetail, expandable: true },
      { key: 'endingBeat', label: 'Ending Beat', value: idea => idea.endingBeat, expandable: true },
      { key: 'caption', label: 'Caption', value: idea => idea.caption, expandable: true },
      { key: 'pinnedComment', label: 'Pinned Comment', value: idea => idea.pinnedComment, expandable: true },
      { key: 'setting', label: 'Setting', value: idea => idea.setting, expandable: true },
      { key: 'sceneDetail', label: 'Scene Detail', value: idea => idea.sceneDetail, expandable: true },
      { key: 'dialogue', label: 'Dialogue', value: idea => idea.dialogue, expandable: true },
      { key: 'defaultCast', label: 'Default Cast', value: idea => idea.defaultCast },
      {
        key: 'dimensionFeedback',
        label: 'Dimension Feedback (explanation / works / improvement)',
        value: (_idea, rating) => rating?.dimensionScores,
        expandable: true,
      },
      { key: 'criticalFindings', label: 'Critical Findings', value: (_idea, rating) => rating?.criticalFindings, expandable: true },
      { key: 'majorFindings', label: 'Major Findings', value: (_idea, rating) => rating?.majorFindings, expandable: true },
      { key: 'minorFindings', label: 'Minor Findings', value: (_idea, rating) => rating?.minorFindings, expandable: true },
      { key: 'suggestions', label: 'Suggestions', value: (_idea, rating) => rating?.suggestions, expandable: true },
      { key: 'evaluationMode', label: 'Evaluation Mode', value: (_idea, rating) => rating?.evaluationMode },
      { key: 'evaluatedAt', label: 'Evaluated At', value: (_idea, rating) => rating?.evaluatedAt },
      { key: 'evaluationVersion', label: 'Evaluation Version', value: (_idea, rating) => rating?.evaluationVersion },
      { key: 'allIdeaData', label: 'Complete Idea Data (JSON)', value: idea => idea, expandable: true },
      { key: 'allRatingData', label: 'Complete Rating Data (JSON)', value: (_idea, rating) => rating, expandable: true },
    );
    return columns;
  },

  async exportAllIdeasCsv() {
    const columns = this.getFullTableColumns();
    const rows = this.getAllIdeaRows();
    const csvCell = value => {
      let text = value == null ? '' : typeof value === 'string' ? value : JSON.stringify(value);
      if (/^[\s]*[=+\-@]/.test(text)) text = `'${text}`;
      return `"${text.replace(/"/g, '""')}"`;
    };
    const csv = [
      columns.map(column => csvCell(column.label)).join(','),
      ...rows.map(({ idea, rating }) => columns
        .map(column => csvCell(column.value(idea, rating)))
        .join(',')),
    ].join('\r\n');
    this.downloadBlob(`\uFEFF${csv}`, 'content_ideas_full_table.csv', 'text/csv;charset=utf-8');
    this.showToast(`Exported ${rows.length} ideas to CSV.`, 'success');
  },

  async exportAllIdeasJson() {
    const rows = this.getAllIdeaRows().map(({ idea, rating }) => ({ idea, rating }));
    this.downloadBlob(JSON.stringify(rows, null, 2), 'content_ideas_full_table.json', 'application/json;charset=utf-8');
    this.showToast(`Exported ${rows.length} ideas to JSON.`, 'success');
  },

  downloadBlob(content, filename, contentType) {
    const blob = new Blob([content], { type: contentType });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = filename;
    link.click();
    setTimeout(() => URL.revokeObjectURL(url), 1000);
  },

  async exportRatingsJson() {
    if (this.ratings.length === 0) {
      this.showToast('No ratings to export.', 'error');
      return;
    }
    const res = await fetch(`${API_BASE}/api/export/json`);
    const blob = await res.blob();
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'content_ratings.json';
    a.click();
    URL.revokeObjectURL(url);
    this.showToast('JSON exported.', 'success');
  },

  async exportRatingsCsv() {
    if (this.ratings.length === 0) {
      this.showToast('No ratings to export.', 'error');
      return;
    }
    const res = await fetch(`${API_BASE}/api/export/csv`);
    const blob = await res.blob();
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'content_ratings.csv';
    a.click();
    URL.revokeObjectURL(url);
    this.showToast('CSV exported.', 'success');
  },

  renderLibrary() {
    const search = document.getElementById('libSearch').value.toLowerCase();
    const cat = document.getElementById('libCategory').value;
    const verdict = document.getElementById('libVerdict').value;
    const status = document.getElementById('libStatus').value;

    const container = document.getElementById('libList');
    container.innerHTML = '';

    let filtered = this.ideas.filter(i => {
      const matchesSearch = i.title.toLowerCase().includes(search) ||
        i.opening.toLowerCase().includes(search) ||
        i.id.toLowerCase().includes(search);
      const matchesCat = !cat || i.category === cat;
      const rating = this.getRatingForIdea(i.id);
      const matchesVerdict = !verdict || (rating && rating.verdict === verdict);
      const matchesStatus = !status ||
        (status === 'evaluated' && !!rating) ||
        (status === 'unevaluated' && !rating) ||
        (status === 'failed' && rating && rating.evaluationMode === 'failed');
      return matchesSearch && matchesCat && matchesVerdict && matchesStatus;
    });

    if (filtered.length === 0) {
      container.innerHTML = '<div class="empty-state"><h3>No ideas found</h3><p>Try adjusting your filters.</p></div>';
      return;
    }

    filtered.forEach(idea => {
      const rating = this.getRatingForIdea(idea.id);
      const card = document.createElement('div');
      card.className = 'idea-card';
      card.onclick = () => this.openIdeaModal(idea);

      const statusClass = rating ? 'status-evaluated' : 'status-unevaluated';
      const statusText = rating ? 'Evaluated' : 'Not Evaluated';
      const scoreHtml = rating
        ? `<span class="stat-value-mini">${rating.overallScore}</span>`
        : '<span class="stat-value-mini">-</span>';

      card.innerHTML = `
        <div class="idea-card-header">
          <span class="idea-id">${idea.id}</span>
          <span class="status-tag ${statusClass}">${statusText}</span>
        </div>
        <h3 class="idea-title">${this.escapeHtml(idea.title)}</h3>
        <div class="idea-category">${this.escapeHtml(idea.category)}</div>
        <p class="idea-opening">${this.escapeHtml(idea.opening)}</p>
        <div class="idea-meta">
          <span>Cast: ${(idea.defaultCast || []).join(', ') || 'none'}</span>
          ${idea.archived ? '<span>Archived</span>' : ''}
        </div>
      `;
      container.appendChild(card);
    });
  },

  async openIdeaModal(idea) {
    this.selectedIdea = idea;
    const rating = this.getRatingForIdea(idea.id);

    const body = document.getElementById('modalBody');
    body.innerHTML = `
      <div class="idea-detail-section">
        <h3>Idea Information</h3>
        <div class="idea-detail-field"><div class="field-label">ID</div><div class="field-value">${idea.id}</div></div>
        <div class="idea-detail-field"><div class="field-label">Title</div><div class="field-value">${this.escapeHtml(idea.title)}</div></div>
        <div class="idea-detail-field"><div class="field-label">Category</div><div class="field-value">${this.escapeHtml(idea.category)}</div></div>
        <div class="idea-detail-field"><div class="field-label">Cover</div><div class="field-value">${this.escapeHtml(idea.cover)}</div></div>
        <div class="idea-detail-field"><div class="field-label">Opening Hook</div><div class="field-value">${this.escapeHtml(idea.opening)}</div></div>
        <div class="idea-detail-field"><div class="field-label">Problem</div><div class="field-value">${this.escapeHtml(idea.problem)}</div></div>
        <div class="idea-detail-field"><div class="field-label">Lesson</div><div class="field-value">${this.escapeHtml(idea.lesson)}</div></div>
        <div class="idea-detail-field"><div class="field-label">Ending Beat</div><div class="field-value">${this.escapeHtml(idea.endingBeat)}</div></div>
        <div class="idea-detail-field"><div class="field-label">Caption</div><div class="field-value">${this.escapeHtml(idea.caption)}</div></div>
        <div class="idea-detail-field"><div class="field-label">Cast</div><div class="field-value">${(idea.defaultCast || []).join(', ') || 'none'}</div></div>
        <div class="idea-detail-field"><div class="field-label">Setting</div><div class="field-value">${this.escapeHtml(idea.setting)}</div></div>
        <div class="idea-detail-field"><div class="field-label">Story Detail</div><div class="field-value">${this.escapeHtml(idea.storyDetail)}</div></div>
      </div>
      ${rating ? `
      <div class="idea-detail-section">
        <h3>Previous Evaluation</h3>
        <div class="idea-detail-field"><div class="field-label">Score</div><div class="field-value">${rating.overallScore}/100</div></div>
        <div class="idea-detail-field"><div class="field-label">Verdict</div><div class="field-value">${rating.verdict}</div></div>
        <div class="idea-detail-field"><div class="field-label">Mode</div><div class="field-value">${rating.evaluationMode}</div></div>
        <div class="idea-detail-field"><div class="field-label">Critical</div><div class="field-value">${rating.criticalFindings?.length || 0}</div></div>
        <div class="idea-detail-field"><div class="field-label">Major</div><div class="field-value">${rating.majorFindings?.length || 0}</div></div>
        <div class="idea-detail-field"><div class="field-label">Minor</div><div class="field-value">${rating.minorFindings?.length || 0}</div></div>
      </div>
      ` : '<div class="idea-detail-section"><h3>Previous Evaluation</h3><p>This idea has not been evaluated yet.</p></div>'};
    `;

    document.getElementById('ideaModal').style.display = 'flex';
  },

  closeModal() {
    document.getElementById('ideaModal').style.display = 'none';
    this.selectedIdea = null;
  },

  async evaluateSelected() {
    if (!this.selectedIdea) return;
    const ideaId = this.selectedIdea.id;
    this.closeModal();
    await this.evaluateIdea(ideaId, 'offline');
  },

  async evaluateIdea(ideaId, mode = 'offline') {
    const idea = this.ideas.find(i => i.id === ideaId);
    if (!idea) return;

    this.showToast(`Evaluating "${idea.title}"...`, 'info');

    try {
      const res = await fetch(`${API_BASE}/api/evaluate/${ideaId}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ mode }),
      });

      if (!res.ok) {
        const err = await res.json().catch(() => ({}));
        throw new Error(err.error || `Evaluation failed (${res.status})`);
      }

      const result = await res.json();
      await this.loadRatings();
      this.renderDashboard();
      this.renderLibrary();
      this.showResultModal(result);
      this.showToast('Evaluation complete.', 'success');
    } catch (e) {
      this.showToast('Evaluation failed: ' + e.message, 'error');
    }
  },

  showResultModal(result) {
    this.resultModalData = result;
    const body = document.getElementById('resultBody');
    const capped = result.scoreCapped ? '<span style="color:#c0392b; font-weight:600;"> (capped at 59 due to critical findings)</span>' : '';
    const verdictClass = `verdict-${result.verdict.toLowerCase().replace(' ', '-')}`;

    let dimsHtml = '';
    result.dimensionScores.forEach(d => {
      dimsHtml += `
        <div class="dimension-card">
          <div class="dim-header">
            <span class="dim-name">${d.name}</span>
            <span class="dim-score">${d.score}/10</span>
            <span class="dim-weight">${d.weight}%</span>
          </div>
          <div class="dim-text"><strong>Explanation:</strong> ${this.escapeHtml(d.explanation)}</div>
          ${d.whatWorks ? `<div class="dim-text" style="margin-top:0.25rem;"><strong>Works:</strong> ${this.escapeHtml(d.whatWorks)}</div>` : ''}
          ${d.needsImprovement ? `<div class="dim-text" style="margin-top:0.25rem;"><strong>Improve:</strong> ${this.escapeHtml(d.needsImprovement)}</div>` : ''}
        </div>
      `;
    });

    let findingsHtml = '';
    [['Critical', result.criticalFindings, 'finding-critical', 'sev-critical'],
     ['Major', result.majorFindings, 'finding-major', 'sev-major'],
     ['Minor', result.minorFindings, 'finding-minor', 'sev-minor'],
     ['Suggestions', result.suggestions, 'finding-suggestion', 'sev-suggestion']].forEach(([sevName, items, cardClass, sevClass]) => {
      if (items.length === 0) return;
      findingsHtml += `<h4>${sevName} (${items.length})</h4>`;
      items.forEach(f => {
        findingsHtml += `
          <div class="finding-card ${cardClass}">
            <div class="finding-header">
              <span class="finding-title">${this.escapeHtml(f.title)}</span>
              <span class="finding-sev ${sevClass}">${sevName}</span>
            </div>
            <div class="finding-text">${this.escapeHtml(f.explanation)}</div>
            ${f.evidence ? `<div class="finding-evidence">Evidence: ${this.escapeHtml(f.evidence)}</div>` : ''}
            ${f.suggestedFix ? `<div class="finding-fix">Fix: ${this.escapeHtml(f.suggestedFix)}</div>` : ''}
            ${f.original ? `<div style="margin-top:0.5rem;"><strong>Original:</strong> ${this.escapeHtml(f.original)}</div>` : ''}
            ${f.suggested ? `<div style="margin-top:0.25rem;"><strong>Suggested:</strong> ${this.escapeHtml(f.suggested)}</div>` : ''}
          </div>
        `;
      });
    });

    let improvementsHtml = '';
    if (result.improvedHook || result.storyImprovements || result.improvedCaption) {
      improvementsHtml = `
        <h4>Suggested Improvements</h4>
        <div class="suggestion-card">
          <div class="suggestion-pair">
            <div class="suggestion-col">
              <h5>Improved Hook</h5>
              <p>${this.escapeHtml(result.improvedHook || '(none provided)')}</p>
            </div>
            <div class="suggestion-col">
              <h5>Improved Caption</h5>
              <p>${this.escapeHtml(result.improvedCaption || '(none provided)')}</p>
            </div>
          </div>
          <div class="suggestion-col" style="grid-column: 1 / -1;">
            <h5>Story Improvements</h5>
            <p>${this.escapeHtml(result.storyImprovements || '(none provided)')}</p>
          </div>
        </div>
      `;
    }

    body.innerHTML = `
      <div class="score-display">
        <div class="score-circle">
          <div>${result.overallScore}</div>
          <div class="score-label">Overall Score</div>
        </div>
        <div class="score-verdict verdict-${verdictClass}">${result.verdict}</div>
        <div style="font-size:0.9rem; color:var(--text-muted);">
          Mode: <strong>${result.evaluationMode}</strong> ${capped}<br>
          Critical: ${result.criticalFindings.length} | Major: ${result.majorFindings.length} | Minor: ${result.minorFindings.length} | Suggestions: ${result.suggestions.length}<br>
          Evaluated: ${new Date(result.evaluatedAt).toLocaleString()}
        </div>
      </div>
      <div class="dimensions-grid">${dimsHtml}</div>
      ${findingsHtml}
      ${improvementsHtml}
    `;

    document.getElementById('resultModal').style.display = 'flex';
  },

  closeResultModal() {
    document.getElementById('resultModal').style.display = 'none';
  },

  async copyResult() {
    if (!this.resultModalData) return;
    const r = this.resultModalData;
    
    let text = `Content Idea Evaluation Result\n`;
    text += `==============================\n`;
    text += `ID: ${r.ideaId}\n`;
    text += `Overall Score: ${r.overallScore}/100\n`;
    text += `Verdict: ${r.verdict}\n`;
    text += `Score Capped: ${r.scoreCapped ? 'Yes (59)' : 'No'}\n`;
    text += `Evaluation Mode: ${r.evaluationMode}\n`;
    text += `Evaluated At: ${new Date(r.evaluatedAt).toLocaleString()}\n`;
    text += `Evaluation Version: ${r.evaluationVersion}\n`;
    text += `\n`;
    
    text += `=== TEN DIMENSION SCORES ===\n`;
    for (const d of r.dimensionScores) {
      text += `${d.name} (${d.weight}%): ${d.score}/10\n`;
      text += `  Explanation: ${d.explanation}\n`;
      if (d.whatWorks) text += `  What Works: ${d.whatWorks}\n`;
      if (d.needsImprovement) text += `  Needs Improvement: ${d.needsImprovement}\n`;
      text += `\n`;
    }
    
    text += `=== CRITICAL FINDINGS (${r.criticalFindings.length}) ===\n`;
    for (const f of r.criticalFindings) {
      text += `- ${f.title}\n`;
      text += `  Explanation: ${f.explanation}\n`;
      text += `  Evidence: ${f.evidence}\n`;
      text += `  Fix: ${f.suggestedFix}\n`;
    }
    text += `\n`;
    
    text += `=== MAJOR FINDINGS (${r.majorFindings.length}) ===\n`;
    for (const f of r.majorFindings) {
      text += `- ${f.title}\n`;
      text += `  Explanation: ${f.explanation}\n`;
      text += `  Evidence: ${f.evidence}\n`;
      text += `  Fix: ${f.suggestedFix}\n`;
    }
    text += `\n`;
    
    text += `=== MINOR FINDINGS (${r.minorFindings.length}) ===\n`;
    for (const f of r.minorFindings) {
      text += `- ${f.title}\n`;
      text += `  Explanation: ${f.explanation}\n`;
      text += `  Evidence: ${f.evidence}\n`;
      text += `  Fix: ${f.suggestedFix}\n`;
    }
    text += `\n`;
    
    text += `=== SUGGESTIONS (${r.suggestions.length}) ===\n`;
    for (const s of r.suggestions) {
      text += `- ${s.title}\n`;
      text += `  Explanation: ${s.explanation}\n`;
      if (s.original) text += `  Original: ${s.original}\n`;
      if (s.suggested) text += `  Suggested: ${s.suggested}\n`;
      text += `\n`;
    }
    
    text += `=== IMPROVEMENTS ===\n`;
    if (r.improvedHook) text += `Improved Hook: ${r.improvedHook}\n`;
    if (r.storyImprovements) text += `Story Improvements: ${r.storyImprovements}\n`;
    if (r.improvedCaption) text += `Improved Caption: ${r.improvedCaption}\n`;
    
    try {
      if (navigator.clipboard && navigator.clipboard.writeText) {
        await navigator.clipboard.writeText(text);
        this.showToast('Result copied to clipboard!', 'success');
      } else {
        // Fallback for older browsers or non-secure contexts
        const textarea = document.createElement('textarea');
        textarea.value = text;
        textarea.style.position = 'fixed';
        textarea.style.left = '-9999px';
        textarea.style.top = '-9999px';
        document.body.appendChild(textarea);
        textarea.focus();
        textarea.select();
        document.execCommand('copy');
        document.body.removeChild(textarea);
        this.showToast('Result copied to clipboard!', 'success');
      }
    } catch (e) {
      console.error('Copy failed:', e);
      this.showToast('Copy failed. Please try again.', 'error');
    }
  },

  async batchEvaluateAll() {
    if (!confirm(`Evaluate all ${this.ideas.length} ideas? This may take a while.`)) return;
    const unevaluated = this.ideas.filter(i => !this.getRatingForIdea(i.id));
    await this.batchEvaluateIds(unevaluated.map(i => i.id));
  },

  async batchReEvaluateAll() {
    if (!confirm(`Re-evaluate all ${this.ideas.length} ideas? This will overwrite existing ratings and may take a while.`)) return;
    await this.batchEvaluateIds(this.ideas.map(i => i.id));
  },

  async batchEvaluateUnevaluated() {
    const unevaluated = this.ideas.filter(i => !this.getRatingForIdea(i.id));
    if (unevaluated.length === 0) {
      this.showToast('All ideas already evaluated.', 'info');
      return;
    }
    await this.batchEvaluateIds(unevaluated.map(i => i.id));
  },

  async batchEvaluateIds(ids) {
    let completed = 0;
    const total = ids.length;
    for (const id of ids) {
      try {
        await this.evaluateIdea(id, 'offline');
        completed++;
        this.showToast(`Progress: ${completed}/${total}`, 'info');
        // Small delay to avoid overwhelming
        await new Promise(r => setTimeout(r, 100));
      } catch (e) {
        console.error(`Failed to evaluate ${id}:`, e);
      }
    }
    await this.loadRatings();
    this.renderDashboard();
    this.renderLibrary();
    this.showToast(`Batch complete: ${completed}/${total} evaluated.`, 'success');
  },

  async exportJson() {
    const res = await fetch(`${API_BASE}/api/export/json`);
    const blob = await res.blob();
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'content_ratings.json';
    a.click();
    URL.revokeObjectURL(url);
  },

  async exportCsv() {
    const res = await fetch(`${API_BASE}/api/export/csv`);
    const blob = await res.blob();
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'content_ratings.csv';
    a.click();
    URL.revokeObjectURL(url);
  },

  async clearRatings() {
    if (!confirm('Delete all saved ratings? This cannot be undone.')) return;
    const res = await fetch(`${API_BASE}/api/ratings`, { method: 'DELETE' });
    const data = await res.json();
    await this.loadRatings();
    this.renderDashboard();
    this.renderLibrary();
    this.showToast(`Cleared ${data.cleared} ratings.`, 'success');
  },

  showToast(message, type = 'info') {
    const toast = document.getElementById('toast');
    toast.textContent = message;
    toast.className = `toast show ${type}`;
    setTimeout(() => toast.classList.remove('show'), 3000);
  },

  escapeHtml(text) {
    if (!text) return '';
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
  },
};

// Initialize when DOM ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', () => app.init());
} else {
  app.init();
}
