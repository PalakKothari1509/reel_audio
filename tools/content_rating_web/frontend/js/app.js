/* Content Rating Tool — Main Application Controller */

const API_BASE = '';

const app = {
  ideas: [],
  ratings: [],
  freshness: [],
  failedIdeas: new Set(),
  sort: 'idAsc',
  selectedIdea: null,
  currentView: 'dashboard',

  async init() {
    this.setupNavigation();
    this.setupSearch();
    await this.loadIdeas();
    await this.loadRatings();
    await this.loadFreshness();
    this.renderDashboard();
    this.showToast('Content Rating Tool loaded. Offline mode ready.', 'info');

    // Escape key closes the topmost open modal
    document.addEventListener('keydown', (e) => {
      if (e.key !== 'Escape') return;
      const resultModal = document.getElementById('resultModal');
      const ideaModal = document.getElementById('ideaModal');
      const repairModal = document.getElementById('repairModal');
      const repairHistoryModal = document.getElementById('repairHistoryModal');
      if (resultModal.style.display === 'flex') {
        this.closeResultModal();
      } else if (repairModal.style.display === 'flex') {
        this.closeRepairModal();
      } else if (repairHistoryModal.style.display === 'flex') {
        this.closeRepairHistoryModal();
      } else if (ideaModal.style.display === 'flex') {
        this.closeModal();
      }
    });
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
    const sort = document.getElementById('libSort');
    sort.addEventListener('change', () => {
      this.sort = sort.value;
      this.renderLibrary();
    });
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

  async loadFreshness() {
    try {
      const res = await fetch(`${API_BASE}/api/freshness`);
      const data = await res.json();
      this.freshness = data.results || [];
    } catch (e) {
      this.showToast('Failed to load freshness: ' + e.message, 'error');
    }
  },

  getRatingForIdea(ideaId) {
    return this.ratings.find(r => r.ideaId === ideaId);
  },

  sortIdeas(filtered) {
    const sorted = [...filtered];
    const sort = this.sort || 'idAsc';

    const verdictOrder = {
      'Ready to Post': 0,
      'Needs Minor Fixes': 1,
      'Needs Major Rewrite': 2,
      Reject: 3,
    };

    const freshnessOrder = {
      CURRENT: 0,
      NEEDS_REEVALUATION: 1,
      LEGACY: 2,
      NOT_EVALUATED: 3,
    };

    sorted.sort((a, b) => {
      const ideaA = this.ideas.find(i => i.id === a.ideaId);
      const ideaB = this.ideas.find(i => i.id === b.ideaId);
      const ratingA = this.ratings.find(r => r.ideaId === a.ideaId);
      const ratingB = this.ratings.find(r => r.ideaId === b.ideaId);

      switch (sort) {
        case 'scoreHigh': {
          const scoreA = ratingA ? ratingA.overallScore : -1;
          const scoreB = ratingB ? ratingB.overallScore : -1;
          return scoreB - scoreA || a.ideaId.localeCompare(b.ideaId);
        }
        case 'scoreLow': {
          const scoreA = ratingA ? ratingA.overallScore : 101;
          const scoreB = ratingB ? ratingB.overallScore : 101;
          return scoreA - scoreB || a.ideaId.localeCompare(b.ideaId);
        }
        case 'verdict': {
          const va = verdictOrder[ratingA?.verdict] ?? 99;
          const vb = verdictOrder[ratingB?.verdict] ?? 99;
          return va - vb || a.ideaId.localeCompare(b.ideaId);
        }
        case 'freshness': {
          const fa = freshnessOrder[a.status] ?? 99;
          const fb = freshnessOrder[b.status] ?? 99;
          return fa - fb || a.ideaId.localeCompare(b.ideaId);
        }
        case 'idDesc': {
          return b.ideaId.localeCompare(a.ideaId);
        }
        case 'idAsc':
        default:
          return a.ideaId.localeCompare(b.ideaId);
      }
    });

    return sorted;
  },

  clearAllFilters() {
    document.getElementById('libSearch').value = '';
    document.getElementById('libCategory').value = '';
    document.getElementById('libVerdict').value = '';
    document.getElementById('libStatus').value = '';
    document.getElementById('libSort').value = 'idAsc';
    this.sort = 'idAsc';
    this.renderLibrary();
  },

  renderDashboard() {
    const total = this.ideas.length;
    const current = this.freshness.filter(f => f.status === 'CURRENT').length;
    const needsReevaluation = this.freshness.filter(f => f.status === 'NEEDS_REEVALUATION' || f.status === 'LEGACY').length;
    const notEvaluated = this.freshness.filter(f => f.status === 'NOT_EVALUATED').length;
    const ready = this.freshness.filter(f => f.rating && f.rating.verdict === 'Ready to Post').length;
    const minor = this.freshness.filter(f => f.rating && f.rating.verdict === 'Needs Minor Fixes').length;
    const major = this.freshness.filter(f => f.rating && f.rating.verdict === 'Needs Major Rewrite').length;
    const reject = this.freshness.filter(f => f.rating && f.rating.verdict === 'Reject').length;

    document.getElementById('statTotal').textContent = total;
    document.getElementById('statEvaluated').textContent = this.ratings.length;
    document.getElementById('statCurrent').textContent = current;
    document.getElementById('statNeedsReevaluation').textContent = needsReevaluation;
    document.getElementById('statNotEvaluated').textContent = notEvaluated;
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

    // Current → filter by current status
    document.getElementById('statCurrent').parentElement.onclick = () => {
      document.getElementById('libSearch').value = '';
      document.getElementById('libCategory').value = '';
      document.getElementById('libVerdict').value = '';
      document.getElementById('libStatus').value = 'current';
      this.navigateTo('library');
      this.renderLibrary();
    };

    // Needs Re-evaluation → filter by stale status
    document.getElementById('statNeedsReevaluation').parentElement.onclick = () => {
      document.getElementById('libSearch').value = '';
      document.getElementById('libCategory').value = '';
      document.getElementById('libVerdict').value = '';
      document.getElementById('libStatus').value = 'needsReevaluation';
      this.navigateTo('library');
      this.renderLibrary();
    };

    // Not Evaluated → filter by not evaluated status
    document.getElementById('statNotEvaluated').parentElement.onclick = () => {
      document.getElementById('libSearch').value = '';
      document.getElementById('libCategory').value = '';
      document.getElementById('libVerdict').value = '';
      document.getElementById('libStatus').value = 'notEvaluated';
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
      { key: 'freshnessStatus', label: 'Freshness', value: (_idea, rating) => {
        const f = this.freshness.find(x => x.ideaId === (_idea && _idea.id));
        return f ? f.status : 'UNKNOWN';
      } },
      { key: 'evaluationStatus', label: 'Evaluation Status', value: (_idea, rating) => rating ? 'Evaluated' : 'Not evaluated' },
      { key: 'overallScore', label: 'Overall Score', value: (_idea, rating) => rating?.overallScore },
      { key: 'rawScore', label: 'Raw Score', value: (_idea, rating) => rating?.rawScore },
      { key: 'verdict', label: 'Verdict', value: (_idea, rating) => rating?.verdict },
      { key: 'scoreCapped', label: 'Score Capped', value: (_idea, rating) => rating ? rating.scoreCapped : '' },
      { key: 'evaluationVersion', label: 'Version', value: (_idea, rating) => rating?.evaluationVersion },
    ];

    const dimensionIds = [
      'hookStrength', 'relatabilityAudienceFit', 'payoffRetention', 'hinglishNaturalness',
      'visualFeasibility', 'soundOffReadability', 'shareSaveTrigger', 'captionCommentPackage',
      'originality', 'audioHook',
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
      { key: 'gateResults', label: 'Gate Results', value: (_idea, rating) => rating?.gateResults, expandable: true },
      { key: 'criticalFindings', label: 'Critical Findings', value: (_idea, rating) => rating?.criticalFindings, expandable: true },
      { key: 'majorFindings', label: 'Major Findings', value: (_idea, rating) => rating?.majorFindings, expandable: true },
      { key: 'minorFindings', label: 'Minor Findings', value: (_idea, rating) => rating?.minorFindings, expandable: true },
      { key: 'suggestions', label: 'Suggestions', value: (_idea, rating) => rating?.suggestions, expandable: true },
      { key: 'fixesToReach10', label: 'Fixes to Reach 100', value: (_idea, rating) => rating?.fixesToReach10, expandable: true },
      { key: 'potentialScore', label: 'Potential Score', value: (_idea, rating) => rating?.potentialScore },
      { key: 'rewrittenHook', label: 'Rewritten Hook', value: (_idea, rating) => rating?.rewrittenHook, expandable: true },
      { key: 'duplicateOf', label: 'Duplicate Of', value: (_idea, rating) => rating?.duplicateOf },
      { key: 'recommendedFormat', label: 'Recommended Format', value: (_idea, rating) => rating?.recommendedFormat },
      { key: 'seasonTag', label: 'Season Tag', value: (_idea, rating) => rating?.seasonTag },
      { key: 'deterministicChecks', label: 'Deterministic Checks', value: (_idea, rating) => rating?.deterministicChecks, expandable: true },
      { key: 'confidence', label: 'Confidence', value: (_idea, rating) => rating?.confidence },
      { key: 'evaluationMode', label: 'Evaluation Mode', value: (_idea, rating) => rating?.evaluationMode },
      { key: 'evaluatedAt', label: 'Evaluated At', value: (_idea, rating) => rating?.evaluatedAt },
      { key: 'evaluationVersion', label: 'Evaluation Version', value: (_idea, rating) => rating?.evaluationVersion },
      { key: 'allIdeaData', label: 'Complete Idea Data (JSON)', value: idea => idea, expandable: true },
      { key: 'allRatingData', label: 'Complete Rating Data (JSON)', value: (_idea, rating) => rating, expandable: true },
    );
    return columns;
  },

  getDimension(rating, dimensionId) {
    return rating?.dimensionScores?.find(dimension => dimension.id === dimensionId);
  },

  // ── Story parsing & completeness helpers ──

  parseStoryDetail(storyDetail) {
    const sections = { story: '', twist: '', resolution: '', moral: '' };
    if (!storyDetail) return sections;

    const lines = storyDetail.split(/\n/);
    let currentSection = null;

    for (const line of lines) {
      const trimmed = line.trim();
      const lower = trimmed.toLowerCase();

      if (lower.startsWith('story:')) {
        currentSection = 'story';
        sections.story = trimmed.replace(/^story:\s*/i, '');
      } else if (lower.startsWith('twist:')) {
        currentSection = 'twist';
        sections.twist = trimmed.replace(/^twist:\s*/i, '');
      } else if (lower.startsWith('resolution:')) {
        currentSection = 'resolution';
        sections.resolution = trimmed.replace(/^resolution:\s*/i, '');
      } else if (lower.startsWith('moral:')) {
        currentSection = 'moral';
        sections.moral = trimmed.replace(/^moral:\s*/i, '');
      } else if (currentSection && trimmed) {
        sections[currentSection] += (sections[currentSection] ? '\n' : '') + trimmed;
      }
    }

    return sections;
  },

  getStoryCompleteness(storyDetail) {
    const sections = this.parseStoryDetail(storyDetail);
    const componentIds = ['story', 'twist', 'resolution', 'moral'];
    const present = componentIds.filter(s => sections[s] && sections[s].trim().length > 0);
    const missing = componentIds.filter(s => !sections[s] || !sections[s].trim());

    return {
      present: present.length,
      total: 4,
      missing: missing,
      isComplete: present.length === 4,
    };
  },

  renderStoryStructure(storyDetail) {
    const sections = this.parseStoryDetail(storyDetail);
    const completeness = this.getStoryCompleteness(storyDetail);
    const sectionLabels = {
      story: 'Story',
      twist: 'Twist',
      resolution: 'Resolution',
      moral: 'Moral',
    };

    const completenessHtml = `
      <div class="story-completeness">
        <span class="completeness-count">${completeness.present}/${completeness.total} components present</span>
        ${completeness.missing.length > 0
          ? `<span class="completeness-missing">Missing: ${completeness.missing.join(', ')}</span>`
          : `<span class="completeness-complete">All components present</span>`}
      </div>
    `;

    const sectionsHtml = [
      { id: 'story', label: 'Story' },
      { id: 'twist', label: 'Twist' },
      { id: 'resolution', label: 'Resolution' },
      { id: 'moral', label: 'Moral' },
    ].map(s => {
      const content = sections[s.id] || '';
      const hasContent = content && content.trim().length > 0;
      return `
        <div class="story-section" id="story-${s.id}">
          <h4 class="story-section-title" data-section="${s.id}">${s.label}</h4>
          <div class="story-section-content" style="white-space: pre-wrap">${hasContent ? this.escapeHtml(content) : '<em>Not provided</em>'}</div>
        </div>
      `;
    }).join('');

    return completenessHtml + sectionsHtml;
  },

  getStoryPreview(storyDetail) {
    const sections = this.parseStoryDetail(storyDetail);
    const storyText = sections.story || '';
    if (!storyText) return '';
    // Return first ~120 chars as a preview
    const preview = storyText.trim().slice(0, 120);
    return preview.length < storyText.trim().length ? preview + '…' : preview;
  },

  getStoryBadgeHtml(storyDetail) {
    const completeness = this.getStoryCompleteness(storyDetail);
    const present = completeness.present;
    const total = completeness.total;

    let badgeClass = 'story-complete';
    if (present === 0) badgeClass = 'story-missing-all';
    else if (present < total) badgeClass = 'story-partial';

    return `
      <span class="story-completeness-badge ${badgeClass}" title="${present}/${total} story components present (${completeness.missing.join(', ')})">
        ${present}/${total}
      </span>
    `;
  },

  getRelevantFinding(rating, category) {
    const collections = [
      rating?.criticalFindings,
      rating?.majorFindings,
      rating?.minorFindings,
      rating?.suggestions,
    ].filter(Array.isArray).flat();
    const keywords = category === 'hook'
      ? ['hook', 'opening']
      : category === 'story'
        ? ['story', 'narrative', 'twist', 'resolution', 'moral']
        : ['caption', 'pinned', 'hashtag', 'comment'];
    return collections.find(item => {
      const text = `${item.title || ''} ${item.explanation || ''}`.toLowerCase();
      return keywords.some(keyword => text.includes(keyword));
    });
  },

  getPinnedCommentProblem(row) {
    return this.getGroupedProblem(row, 'pinned');
  },

  getPinnedCommentSolution(row) {
    return this.getGroupedSolution(row, 'pinned');
  },

  getGroupedProblem(row, category) {
    const dimensionId = category === 'hook'
      ? 'hookStrength'
      : category === 'story'
        ? 'payoffRetention'
        : category === 'pinned'
          ? 'captionCommentPackage'
          : 'captionCommentPackage';
    const dimension = this.getDimension(row.rating, dimensionId);
    if (dimension?.needsImprovement) return dimension.needsImprovement;
    if (category === 'story') return row.idea.problem || 'No story problem identified.';
    if (category === 'pinned') {
      const finding = this.getRelevantFinding(row.rating, category);
      if (finding?.explanation) return finding.explanation;
      if (row.rating?.pinned_comment_problem) return row.rating.pinned_comment_problem;
      return row.idea.pinnedComment || 'No pinned comment problem identified.';
    }
    if (category === 'caption') {
      const finding = this.getRelevantFinding(row.rating, category);
      if (finding?.explanation) return finding.explanation;
    }
    return category === 'hook'
      ? (row.idea.opening || 'No hook problem identified.')
      : category === 'story'
        ? (row.idea.storyDetail || 'No story problem identified.')
        : (row.idea.caption || 'No caption problem identified.');
  },

  getGroupedSolution(row, category) {
    if (category === 'hook') {
      const rewrite = row.rating?.rewrittenHook;
      if (rewrite && !rewrite.includes('...?') && !rewrite.includes('\uFFFD')) return rewrite;
      return row.idea.opening || 'No hook solution identified.';
    }
    if (category === 'story') return row.rating?.storyImprovements || row.idea.lesson || 'No story solution identified.';
    if (category === 'pinned') {
      const rewrite = row.rating?.improvedPinnedComment;
      if (rewrite && !rewrite.includes('\uFFFD')) return rewrite;
      return row.idea.pinnedComment || 'No pinned comment solution identified.';
    }
    if (category === 'caption') {
      const rewrite = row.rating?.improvedCaption;
      if (rewrite && !rewrite.includes('\uFFFD')) return rewrite;
      return row.idea.caption || 'No caption solution identified.';
    }
    return category === 'hook'
      ? (row.idea.opening || 'No hook solution identified.')
      : category === 'story'
        ? row.rating?.storyImprovements || row.idea.lesson || 'No story solution identified.'
        : (row.idea.caption || 'No caption solution identified.');
  },

  getHookProblem(row) {
    return this.getGroupedProblem(row, 'hook');
  },

  getHookSolution(row) {
    return this.getGroupedSolution(row, 'hook');
  },

  getStoryProblem(row) {
    return this.getGroupedProblem(row, 'story');
  },

  getStorySolution(row) {
    return this.getGroupedSolution(row, 'story');
  },

  getCaptionProblem(row) {
    return this.getGroupedProblem(row, 'caption');
  },

  getCaptionSolution(row) {
    return this.getGroupedSolution(row, 'caption');
  },

  async exportAllIdeasCsv() {
    const rows = this.getAllIdeaRows();
    const columns = [
      { label: 'idea_id', value: ({ idea }) => idea.id },
      { label: 'hook_problem', value: row => this.getHookProblem(row) },
      { label: 'hook_solution', value: row => this.getHookSolution(row) },
      { label: 'story_problem', value: row => this.getStoryProblem(row) },
      { label: 'story_solution', value: row => this.getStorySolution(row) },
      { label: 'caption_problem', value: row => this.getCaptionProblem(row) },
      { label: 'caption_solution', value: row => this.getCaptionSolution(row) },
      { label: 'pinned_comment_problem', value: row => this.getPinnedCommentProblem(row) },
      { label: 'pinned_comment_solution', value: row => this.getPinnedCommentSolution(row) },
    ];
    const csvCell = value => {
      let text = value == null ? '' : typeof value === 'string' ? value : JSON.stringify(value);
      if (/^[\s]*[=+\-@]/.test(text)) text = `'${text}`;
      return `"${text.replace(/"/g, '""')}"`;
    };
    const csv = [
      columns.map(column => csvCell(column.label)).join(','),
      ...rows.map(row => columns
        .map(column => csvCell(column.value(row)))
        .join(',')),
    ].join('\r\n');
    this.downloadBlob(`\uFEFF${csv}`, 'content_ideas_problem_solution.csv', 'text/csv;charset=utf-8');
    this.showToast(`Exported ${rows.length} ideas to CSV.`, 'success');
  },

  async exportAllIdeasJson() {
    const rows = this.getAllIdeaRows().map(row => ({
      idea_id: row.idea.id || '',
      hook_problem: this.getHookProblem(row),
      hook_solution: this.getHookSolution(row),
      story_problem: this.getStoryProblem(row),
      story_solution: this.getStorySolution(row),
      caption_problem: this.getCaptionProblem(row),
      caption_solution: this.getCaptionSolution(row),
      pinned_comment_problem: this.getPinnedCommentProblem(row),
      pinned_comment_solution: this.getPinnedCommentSolution(row),
    }));
    this.downloadBlob(JSON.stringify(rows, null, 2), 'content_ideas_problem_solution.json', 'application/json;charset=utf-8');
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

    let filtered = this.freshness.filter(f => {
      const idea = this.ideas.find(i => i.id === f.ideaId);
      if (!idea) return false;
      const matchesSearch = idea.title.toLowerCase().includes(search) ||
        idea.opening.toLowerCase().includes(search) ||
        idea.id.toLowerCase().includes(search);
      const matchesCat = !cat || idea.category === cat;
      const matchesVerdict = !verdict || (f.rating && f.rating.verdict === verdict);
      const matchesStatus = !status ||
        (status === 'current' && f.status === 'CURRENT') ||
        (status === 'needsReevaluation' && (f.status === 'NEEDS_REEVALUATION' || f.status === 'LEGACY')) ||
        (status === 'notEvaluated' && f.status === 'NOT_EVALUATED') ||
        (status === 'evaluated' && !!f.rating) ||
        (status === 'unevaluated' && !f.rating) ||
        (status === 'failed' && this.failedIdeas.has(f.ideaId));
      return matchesSearch && matchesCat && matchesVerdict && matchesStatus;
    });

    let sorted = this.sortIdeas(filtered);

    if (sorted.length === 0) {
      container.innerHTML = '<div class="empty-state"><h3>No ideas found</h3><p>Try adjusting your filters.</p></div>';
      return;
    }

    sorted.forEach(f => {
      const idea = this.ideas.find(i => i.id === f.ideaId);
      const rating = f.rating;
      const card = document.createElement('div');
      card.className = 'idea-card';
      card.onclick = () => this.openIdeaModal(idea);

      const freshnessClass = f.status === 'CURRENT' ? 'status-current'
        : f.status === 'NOT_EVALUATED' ? 'status-unevaluated'
        : 'status-stale';
      const freshnessText = f.status === 'CURRENT' ? 'Current'
        : f.status === 'NOT_EVALUATED' ? 'Not Evaluated'
        : f.status === 'LEGACY' ? 'Legacy - Re-evaluate'
        : 'Stale - Re-evaluate';

      const statusClass = rating ? 'status-evaluated' : 'status-unevaluated';
      const statusText = rating ? 'Evaluated' : 'Not Evaluated';
      const scoreHtml = rating
        ? `<span class="stat-value-mini">${rating.overallScore}</span>`
        : '<span class="stat-value-mini">-</span>';

      const verdictClass = rating
        ? `verdict-badge verdict-${rating.verdict.toLowerCase().replace(' ', '-')}`
        : 'verdict-badge verdict-none';
      const verdictText = rating ? rating.verdict : 'Not Evaluated';

      const dimShort = {
        hookStrength: 'Hook',
        relatabilityAudienceFit: 'Relatability',
        payoffRetention: 'Payoff',
        hinglishNaturalness: 'Hinglish',
        visualFeasibility: 'Visual',
        soundOffReadability: 'Sound-Off',
        shareSaveTrigger: 'Share',
        captionCommentPackage: 'Caption',
        originality: 'Originality',
        audioHook: 'Audio Hook',
      };
      const dimScores = rating?.dimensionScores || [];
      const dimBadges = dimScores
        .slice(0, 4)
        .map(d => {
          const label = dimShort[d.id] || d.id;
          return `<span class="dim-badge" title="${d.id}: ${d.score}/10">${label} ${d.score}</span>`;
        })
        .join('');

      const dupIds = rating?.duplicateOf || [];
      const dupTitles = dupIds.map(id => {
        const refIdea = this.ideas.find(i => i.id === id);
        return refIdea ? `${id}: ${refIdea.title}` : id;
      });
      const dupBadge = dupIds.length > 0
        ? `<span class="dup-badge" title="Duplicate of: ${dupTitles.join(', ')}">Dup: ${dupIds.length}</span>`
        : '';

      card.innerHTML = `
        <div class="idea-card-header">
          <span class="idea-id">${idea.id}</span>
          <span class="status-tag ${statusClass}">${statusText}</span>
          <span class="freshness-tag ${freshnessClass}">${freshnessText}</span>
          <span class="${verdictClass}">${verdictText}</span>
          ${dupBadge}
        </div>
        <h3 class="idea-title">${this.escapeHtml(idea.title)}</h3>
        <div class="idea-category">${this.escapeHtml(idea.category)}</div>
        <p class="idea-opening">${this.escapeHtml(idea.opening)}</p>
        <div class="idea-meta">
          <span>Cast: ${(idea.defaultCast || []).join(', ') || 'none'}</span>
          ${idea.archived ? '<span>Archived</span>' : ''}
        </div>
        ${dimBadges ? `<div class="idea-dim-badges">${dimBadges}</div>` : ''}
        <div class="idea-story-preview">
          <div class="story-preview">${this.escapeHtml(this.getStoryPreview(idea.storyDetail))}</div>
          <div class="story-completeness-badge">
            ${this.getStoryBadgeHtml(idea.storyDetail)}
          </div>
        </div>
      `;
      container.appendChild(card);
    });
  },

  async openIdeaModal(idea) {
    this.selectedIdea = idea;
    const rating = this.getRatingForIdea(idea.id);
    const fresh = this.freshness.find(f => f.ideaId === idea.id);
    const freshnessStatus = fresh ? fresh.status : 'UNKNOWN';

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
        <div class="idea-detail-section-story">
          <div class="idea-detail-field">
            <div class="field-label">Story Structure</div>
            <div class="field-value story-completeness" style="white-space: pre-wrap">${this.renderStoryStructure(idea.storyDetail)}</div>
          </div>
        </div>
        <div class="idea-detail-field"><div class="field-label">Production Prompt</div><div class="field-value prompt-text" style="white-space: pre-wrap">${idea.readyPrompt ? this.escapeHtml(idea.readyPrompt) : '<em>No production prompt available.</em>'}</div><button class="btn btn-secondary" style="font-size:0.8rem;margin-top:0.25rem;" onclick="app.copyPrompt('${idea.id}')">Copy Prompt</button></div>
        <div class="idea-detail-field"><div class="field-label">Freshness</div><div class="field-value">${freshnessStatus}</div></div>
        ${rating && rating.duplicateOf && rating.duplicateOf.length > 0 ? `
        <div class="idea-detail-field"><div class="field-label">Duplicate Of</div><div class="field-value">
          ${rating.duplicateOf.map(id => {
            const refIdea = this.ideas.find(i => i.id === id);
            if (refIdea) {
              return `<span style="color:var(--primary);cursor:pointer;text-decoration:underline;" onclick="app.openIdeaModal(app.ideas.find(i => i.id === '${id}'))">${id}: ${refIdea.title}</span>`;
            }
            return id;
          }).join(', ')}
        </div></div>
        ` : ''}
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
        <div class="idea-detail-field"><div class="field-label">Suggestions</div><div class="field-value">${rating.suggestions?.length || 0}</div></div>
        <div class="idea-detail-field"><div class="field-label">Content Hash</div><div class="field-value">${rating.contentHash || 'none'}</div></div>
        <div class="idea-detail-field">
          <div class="field-label">Actions</div>
          <div class="field-value">
            ${freshnessStatus !== 'CURRENT' ? `<button onclick="app.reevaluateIdea('${idea.id}')">Re-evaluate</button>` : ''}
            ${rating && (rating.criticalFindings?.length > 0 || rating.majorFindings?.length > 0 || rating.minorFindings?.length > 0 || rating.suggestions?.length > 0)
              ? `<button class="btn btn-primary" style="font-size:0.85rem;padding:0.4rem 0.8rem;margin:0.25rem 0.25rem 0 0;" onclick="app.repairIdea('${idea.id}', 'online')">Fix All Issues &amp; Update Idea (AI)</button>`
              : ''}
            ${rating ? `<button class="btn btn-secondary" style="font-size:0.85rem;padding:0.4rem 0.8rem;margin:0.25rem 0.25rem 0 0;" onclick="app.repairIdea('${idea.id}', 'offline')">Fix All Issues &amp; Update Idea (Offline)</button>` : ''}
            <button class="btn btn-secondary" style="font-size:0.85rem;padding:0.4rem 0.8rem;margin:0.25rem 0.25rem 0 0;" onclick="app.showRepairHistory('${idea.id}')">Repair History</button>
          </div>
        </div>
      </div>
      ` : '<div class="idea-detail-section"><h3>Previous Evaluation</h3><p>This idea has not been evaluated yet.</p><div class="idea-detail-field"><div class="field-label">Action</div><div class="field-value"><button onclick="app.reevaluateIdea(\'' + idea.id + '\')">Evaluate Now</button></div></div></div>'};
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
      this.failedIdeas.delete(ideaId);
      await this.loadRatings();
      this.renderDashboard();
      this.renderLibrary();
      this.showResultModal(result);
      this.showToast('Evaluation complete.', 'success');
    } catch (e) {
      this.failedIdeas.add(ideaId);
      this.showToast('Evaluation failed: ' + e.message, 'error');
    }
  },

  showResultModal(result) {
    this.resultModalData = result;
    const body = document.getElementById('resultBody');
    const capped = result.scoreCapped ? '<span style="color:#c0392b; font-weight:600;"> (capped)</span>' : '';
    const verdictClass = `verdict-${result.verdict.toLowerCase().replace(' ', '-')}`;
    const isV1 = result.evaluationVersion && result.evaluationVersion.startsWith('1.');
    const versionLabel = isV1 ? ' (v1)' : ' (v2)';

    let dimsHtml = '';
    result.dimensionScores.forEach(d => {
      const anchor = d.anchorMatched ? `<span class="dim-anchor">Anchor: ${d.anchorMatched}</span>` : '';
      dimsHtml += `
        <div class="dimension-card">
          <div class="dim-header">
            <span class="dim-name">${d.name}</span>
            <span class="dim-score">${d.score}/10</span>
            <span class="dim-weight">${d.weight}%</span>
            ${anchor}
          </div>
          <div class="dim-text"><strong>Explanation:</strong> ${this.escapeHtml(d.explanation)}</div>
          ${d.whatWorks ? `<div class="dim-text" style="margin-top:0.25rem;"><strong>Works:</strong> ${this.escapeHtml(d.whatWorks)}</div>` : ''}
          ${d.needsImprovement ? `<div class="dim-text" style="margin-top:0.25rem;"><strong>Improve:</strong> ${this.escapeHtml(d.needsImprovement)}</div>` : ''}
        </div>
      `;
    });

    let gateHtml = '';
    if (result.gateResults && result.gateResults.length > 0) {
      gateHtml = '<h4>Gate Results</h4><div class="gates-grid">';
      result.gateResults.forEach(g => {
        const badgeClass = g.passed ? 'gate-pass' : 'gate-fail';
        gateHtml += `
          <div class="gate-card ${badgeClass}">
            <div class="gate-header">
              <span class="gate-name">${this.escapeHtml(g.name)}</span>
              <span class="gate-status">${g.passed ? 'PASS' : 'FAIL'}</span>
            </div>
            <div class="gate-detail">${this.escapeHtml(g.detail)}</div>
            <div class="gate-severity">Severity on fail: ${g.severityOnFail}</div>
          </div>
        `;
      });
      gateHtml += '</div>';
    }

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

    let fixesHtml = '';
    if (result.fixesToReach10 && result.fixesToReach10.length > 0) {
      fixesHtml = '<h4>Fixes to Reach 100</h4><div class="fixes-list">';
      result.fixesToReach10.slice(0, 5).forEach((f, i) => {
        fixesHtml += `
          <div class="fix-item">
            <span class="fix-rank">${i + 1}.</span>
            <span class="fix-text">${this.escapeHtml(f.fix)}</span>
            <span class="fix-dimension">(${f.dimensionId})</span>
            <span class="fix-gain">+${f.estimatedGain} pts</span>
          </div>
        `;
      });
      fixesHtml += `</div><div class="potential-score">Potential Score: ${result.potentialScore || 'N/A'}/100</div>`;
    }

    let metaHtml = '';
    if (!isV1) {
      metaHtml = `
        <div class="meta-grid">
          <div class="meta-item"><strong>Confidence:</strong> ${result.confidence || 'N/A'}</div>
          <div class="meta-item"><strong>Caps Applied:</strong> ${result.capsApplied?.join(', ') || 'none'}</div>
          <div class="meta-item"><strong>Rewritten Hook:</strong> ${this.escapeHtml(result.rewrittenHook || 'N/A')}</div>
          <div class="meta-item"><strong>Duplicate Of:</strong> ${result.duplicateOf?.join(', ') || 'none'}</div>
          <div class="meta-item"><strong>Recommended Format:</strong> ${result.recommendedFormat || 'N/A'}</div>
          <div class="meta-item"><strong>Season Tag:</strong> ${result.seasonTag || 'none'}</div>
        </div>
      `;
    }

    let deterministicHtml = '';
    if (result.deterministicChecks && result.deterministicChecks.length > 0) {
      deterministicHtml = '<h4>Deterministic Checks</h4><div class="deterministic-grid">';
      result.deterministicChecks.forEach(c => {
        const badgeClass = c.passed ? 'check-pass' : 'check-fail';
        deterministicHtml += `
          <div class="check-card ${badgeClass}">
            <div class="check-header">
              <span class="check-id">${c.id}</span>
              <span class="check-status">${c.passed ? 'PASS' : 'FAIL'}</span>
            </div>
            <div class="check-detail">${this.escapeHtml(c.detail)}</div>
            <div class="check-severity">${c.severity} | Gate: ${c.gate}</div>
          </div>
        `;
      });
      deterministicHtml += '</div>';
    }

    let improvementsHtml = '';
    if (result.improvedHook || result.storyImprovements || result.improvedCaption || result.improvedPinnedComment) {
      const statusBadge = (label, pass) => {
        const cls = pass ? 'status-pass' : 'status-improve';
        return `<span class="status-badge ${cls}">${pass ? 'PASS' : 'IMPROVE'}</span> ${label}`;
      };
      const hookStatus = result.rewrittenHook && !result.rewrittenHook.startsWith('PASS');
      const storyStatus = result.storyImprovements && !result.storyImprovements.startsWith('PASS');
      const captionStatus = result.improvedCaption && !result.improvedCaption.startsWith('PASS');
      const pinnedStatus = result.improvedPinnedComment && !result.improvedPinnedComment.startsWith('PASS');
      improvementsHtml = `
        <h4>Section Status</h4>
        <div class="status-grid">
          <div class="status-item">${statusBadge('Hook', !hookStatus)}</div>
          <div class="status-item">${statusBadge('Story', !storyStatus)}</div>
          <div class="status-item">${statusBadge('Caption', !captionStatus)}</div>
          <div class="status-item">${statusBadge('Pinned Comment', !pinnedStatus)}</div>
        </div>
        <div class="suggestion-card">
          ${!hookStatus ? '' : `
          <div class="suggestion-pair">
            <div class="suggestion-col">
              <h5>Hook Problem</h5>
              <p>${this.escapeHtml(result.rewrittenHook.startsWith('PASS') ? 'No hook problem identified.' : result.rewrittenHook)}</p>
            </div>
            <div class="suggestion-col">
              <h5>Hook Solution</h5>
              <p>${this.escapeHtml(result.rewrittenHook)}</p>
            </div>
          </div>
          `}
          ${!storyStatus ? '' : `
          <div class="suggestion-pair">
            <div class="suggestion-col">
              <h5>Story Problem</h5>
              <p>${this.escapeHtml(result.storyImprovements.startsWith('PASS') ? 'No story problem identified.' : result.storyImprovements.slice(0, 200))}</p>
            </div>
            <div class="suggestion-col">
              <h5>Story Solution</h5>
              <p>${this.escapeHtml(result.storyImprovements)}</p>
            </div>
          </div>
          `}
          ${!captionStatus ? '' : `
          <div class="suggestion-pair">
            <div class="suggestion-col">
              <h5>Caption Problem</h5>
              <p>${this.escapeHtml(result.improvedCaption.startsWith('PASS') ? 'No caption problem identified.' : result.improvedCaption.slice(0, 200))}</p>
            </div>
            <div class="suggestion-col">
              <h5>Caption Solution</h5>
              <p>${this.escapeHtml(result.improvedCaption)}</p>
            </div>
          </div>
          `}
          ${!pinnedStatus ? '' : `
          <div class="suggestion-pair">
            <div class="suggestion-col">
              <h5>Pinned Comment Problem</h5>
              <p>${this.escapeHtml(result.pinned_comment_problem || 'No pinned comment problem identified.')}</p>
            </div>
            <div class="suggestion-col">
              <h5>Pinned Comment Solution</h5>
              <p>${this.escapeHtml(result.improvedPinnedComment)}</p>
            </div>
          </div>
          `}
        </div>
      `;
    }

    body.innerHTML = `
      <div class="score-display">
        <div class="score-circle">
          <div>${result.overallScore}</div>
          <div class="score-label">Overall Score</div>
        </div>
        <div class="score-verdict verdict-${verdictClass}">${result.verdict}${versionLabel}</div>
        <div style="font-size:0.9rem; color:var(--text-muted);">
          Mode: <strong>${result.evaluationMode}</strong> ${capped}<br>
          Raw: ${result.rawScore} | Critical: ${result.criticalFindings.length} | Major: ${result.majorFindings.length} | Minor: ${result.minorFindings.length} | Suggestions: ${result.suggestions.length}<br>
          Evaluated: ${new Date(result.evaluatedAt).toLocaleString()} | Version: ${result.evaluationVersion}
        </div>
      </div>
      <div class="dimensions-grid">${dimsHtml}</div>
      ${gateHtml}
      ${findingsHtml}
      ${fixesHtml}
      ${metaHtml}
      ${deterministicHtml}
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
    const isV1 = r.evaluationVersion && r.evaluationVersion.startsWith('1.');

    let text = `Content Idea Evaluation Result\n`;
    text += `==============================\n`;
    text += `ID: ${r.ideaId}\n`;
    text += `Overall Score: ${r.overallScore}/100\n`;
    text += `Raw Score: ${r.rawScore}/100\n`;
    text += `Verdict: ${r.verdict}\n`;
    text += `Score Capped: ${r.scoreCapped ? 'Yes' : 'No'}\n`;
    text += `Caps Applied: ${r.capsApplied?.join(', ') || 'none'}\n`;
    text += `Evaluation Mode: ${r.evaluationMode}\n`;
    text += `Evaluated At: ${new Date(r.evaluatedAt).toLocaleString()}\n`;
    text += `Evaluation Version: ${r.evaluationVersion}\n`;
    if (!isV1) {
      text += `Confidence: ${r.confidence || 'N/A'}\n`;
      text += `Rewritten Hook: ${r.rewrittenHook || 'N/A'}\n`;
      text += `Duplicate Of: ${r.duplicateOf?.join(', ') || 'none'}\n`;
      text += `Recommended Format: ${r.recommendedFormat || 'N/A'}\n`;
      text += `Season Tag: ${r.seasonTag || 'none'}\n`;
    }
    text += `\n`;

    text += `=== DIMENSION SCORES ===\n`;
    for (const d of r.dimensionScores) {
      text += `${d.name} (${d.weight}%): ${d.score}/10`;
      if (d.anchorMatched) text += ` [Anchor: ${d.anchorMatched}]`;
      text += `\n`;
      text += `  Explanation: ${d.explanation}\n`;
      if (d.whatWorks) text += `  What Works: ${d.whatWorks}\n`;
      if (d.needsImprovement) text += `  Needs Improvement: ${d.needsImprovement}\n`;
      text += `\n`;
    }

    if (r.gateResults && r.gateResults.length > 0) {
      text += `=== GATE RESULTS ===\n`;
      for (const g of r.gateResults) {
        text += `${g.name}: ${g.passed ? 'PASS' : 'FAIL'} (severity on fail: ${g.severityOnFail})\n`;
        text += `  ${g.detail}\n`;
      }
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

    if (r.fixesToReach10 && r.fixesToReach10.length > 0) {
      text += `=== FIXES TO REACH 100 ===\n`;
      for (const f of r.fixesToReach10) {
        text += `- ${f.fix} (${f.dimensionId}) +${f.estimatedGain} pts\n`;
      }
      text += `Potential Score: ${r.potentialScore || 'N/A'}/100\n`;
      text += `\n`;
    }

    if (r.deterministicChecks && r.deterministicChecks.length > 0) {
      text += `=== DETERMINISTIC CHECKS ===\n`;
      for (const c of r.deterministicChecks) {
        text += `${c.id}: ${c.passed ? 'PASS' : 'FAIL'} (${c.severity}) - ${c.detail}\n`;
      }
      text += `\n`;
    }

    if (!isV1) {
      text += `=== V2 IMPROVEMENTS ===\n`;
      if (r.rewrittenHook) text += `Rewritten Hook: ${r.rewrittenHook}\n`;
      text += `\n`;
    } else {
      text += `=== IMPROVEMENTS ===\n`;
      if (r.improvedHook) text += `Improved Hook: ${r.improvedHook}\n`;
      if (r.storyImprovements) text += `Story Improvements: ${r.storyImprovements}\n`;
      if (r.improvedCaption) text += `Improved Caption: ${r.improvedCaption}\n`;
    }

    try {
      if (navigator.clipboard && navigator.clipboard.writeText) {
        await navigator.clipboard.writeText(text);
        this.showToast('Result copied to clipboard!', 'success');
      } else {
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

  async copyPrompt(ideaId) {
    const idea = this.ideas.find(i => i.id === ideaId);
    if (!idea || !idea.readyPrompt) {
      this.showToast('No production prompt available.', 'error');
      return;
    }
    try {
      await navigator.clipboard.writeText(idea.readyPrompt);
      this.showToast('Production prompt copied to clipboard!', 'success');
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

  async reevaluateIdea(ideaId) {
    this.showToast(`Re-evaluating "${ideaId}"...`, 'info');
    try {
      const res = await fetch(`${API_BASE}/api/reevaluate/${ideaId}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({}),
      });
      if (!res.ok) {
        const err = await res.json().catch(() => ({}));
        throw new Error(err.error || `Re-evaluation failed (${res.status})`);
      }
      const result = await res.json();
      this.failedIdeas.delete(ideaId);
      await this.loadRatings();
      await this.loadFreshness();
      this.renderDashboard();
      this.renderLibrary();
      this.showToast(`Re-evaluation complete: ${result.status}.`, 'success');
      return result;
    } catch (e) {
      this.failedIdeas.add(ideaId);
      this.showToast('Re-evaluation failed: ' + e.message, 'error');
      throw e;
    }
  },

  async batchReevaluateModified() {
    const stale = this.freshness.filter(f =>
      f.status === 'NEEDS_REEVALUATION' || f.status === 'LEGACY'
    );
    if (stale.length === 0) {
      this.showToast('All evaluations are current.', 'info');
      return;
    }
    if (!confirm(`Re-evaluate ${stale.length} modified idea(s)?`)) return;

    const succeeded = [];
    const failed = [];
    for (const item of stale) {
      try {
        const res = await fetch(`${API_BASE}/api/reevaluate/${item.ideaId}`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({}),
        });
        if (!res.ok) {
          const err = await res.json().catch(() => ({}));
          failed.push({ ideaId: item.ideaId, error: err.error || `Failed (${res.status})` });
          continue;
        }
        const result = await res.json();
        succeeded.push(result);
      } catch (e) {
        failed.push({ ideaId: item.ideaId, error: e.message });
      }
    }

    await this.loadRatings();
    await this.loadFreshness();
    this.renderDashboard();
    this.renderLibrary();
    this.showToast(`Batch re-evaluation complete: ${succeeded.length} succeeded, ${failed.length} failed.`, 'success');
    return { succeeded, failed };
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

  // ── Idea Repair ──
  repairState: null,

  async repairIdea(ideaId, mode = 'offline') {
    const idea = this.ideas.find(i => i.id === ideaId);
    if (!idea) return;

    const rating = this.getRatingForIdea(ideaId);
    if (!rating) {
      this.showToast('Idea must be evaluated before repair.', 'error');
      return;
    }

    const criticalCount = rating.criticalFindings?.length || 0;
    const majorCount = rating.majorFindings?.length || 0;
    const minorCount = rating.minorFindings?.length || 0;
    const suggestionCount = rating.suggestions?.length || 0;

    if (criticalCount === 0 && majorCount === 0 && minorCount === 0 && suggestionCount === 0) {
      this.showToast('No issues found to repair.', 'info');
      return;
    }

    const modeLabel = mode === 'online' ? 'AI (Gemini)' : 'Offline Rule-Based';
    const modeNotice = mode === 'offline'
      ? '\n\nThis will use deterministic rule-based repair (no API key or internet needed).'
      : '\n\nThis will use Gemini AI repair (requires API key and internet connection).';

    const confirmed = confirm(
      `Fix All Issues & Update Idea for "${idea.title}"?\n\n` +
      `Mode: ${modeLabel}\n` +
      `Current Score: ${rating.overallScore}/100 (${rating.verdict})\n` +
      `Issues: ${criticalCount} Critical, ${majorCount} Major, ${minorCount} Minor, ${suggestionCount} Suggestions${modeNotice}\n\n` +
      `The repaired version will be shown for your review before saving.\n\n` +
      `Continue?`
    );
    if (!confirmed) return;

    this.repairState = { ideaId, idea, originalRating: rating, status: 'loading', repairMode: mode };
    this.showRepairModal({
      ideaId,
      idea,
      originalRating: rating,
      status: 'loading',
      repairMode: mode,
    });

    try {
      const res = await fetch(`${API_BASE}/api/ideas/${ideaId}/repair`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ mode }),
      });

      if (!res.ok) {
        const err = await res.json().catch(() => ({}));
        throw new Error(err.error || `Repair failed (${res.status})`);
      }

      const result = await res.json();
      this.repairState = { ...this.repairState, status: 'complete', result };
      this.showRepairModal(result);
      this.showToast('Repair complete. Review the changes below.', 'success');
    } catch (e) {
      this.repairState = { ...this.repairState, status: 'error', error: e.message };
      this.showRepairModal({
        ideaId,
        idea,
        originalRating: rating,
        status: 'error',
        error: e.message,
        repairMode: mode,
      });
      this.showToast('Repair failed: ' + e.message, 'error');
    }
  },

  showRepairModal(data) {
    this.repairModalData = data;
    const body = document.getElementById('repairBody');
    const footer = document.getElementById('repairFooter');
    const title = document.getElementById('repairTitle');

    if (data.status === 'loading') {
      title.textContent = 'Fix All Issues & Update Idea — Processing';
      body.innerHTML = `
        <div class="repair-state loading">
          <span class="repair-spinner"></span>
          <strong>AI is repairing the idea...</strong><br>
          This may take a moment. Please do not click the repair button again.
        </div>
      `;
      footer.innerHTML = `<button class="btn btn-secondary" onclick="app.closeRepairModal()">Cancel</button>`;
      document.getElementById('repairModal').style.display = 'flex';
      return;
    }

    if (data.status === 'error') {
      title.textContent = 'Repair Failed';
      body.innerHTML = `
        <div class="repair-state error">
          <strong>Repair failed:</strong> ${this.escapeHtml(data.error || 'Unknown error')}<br>
          The original idea has not been modified.
        </div>
      `;
      footer.innerHTML = `<button class="btn btn-secondary" onclick="app.closeRepairModal()">Close</button>`;
      document.getElementById('repairModal').style.display = 'flex';
      return;
    }

    // status === 'complete'
    title.textContent = `Fix All Issues & Update Idea — ${(data.originalIdea || data.idea || {}).title}`;
    const orig = data.originalEvaluation || {};
    const rep = data.repairedEvaluation || {};
    const comp = data.comparison || { changedFields: [], unchangedFields: [] };
    const repairMode = data.repairMode || 'offline';
    const modeLabel = repairMode === 'online' ? 'AI (Gemini)' : 'Offline Rule-Based';
    const fixedIssues = data.fixedIssues || [];
    const unresolvedIssues = data.unresolvedIssues || [];

    const scoreChange = rep.overallScore - (orig.overallScore || 0);
    const scoreChangeClass = scoreChange > 0 ? 'repair-score-improved' : scoreChange < 0 ? 'repair-score-declined' : '';
    const scoreChangeSign = scoreChange > 0 ? '+' : '';

    // Build before/after field comparison
    const fieldLabels = {
      id: 'ID', category: 'Category', title: 'Title', cover: 'Cover',
      opening: 'Opening Hook', problem: 'Problem', lesson: 'Lesson',
      postFormat: 'Post Format', strategy: 'Strategy', caption: 'Caption',
      pinnedComment: 'Pinned Comment', forApp: 'For App', usedOn: 'Used On',
      custom: 'Custom', archived: 'Archived', storyDetail: 'Story Detail',
      setting: 'Setting', sceneDetail: 'Scene Detail', dialogue: 'Dialogue',
      mess: 'Mess', innerThought: 'Inner Thought', endingBeat: 'Ending Beat',
      defaultCast: 'Default Cast', keepMoralOffScreen: 'Keep Moral Off Screen',
      quote: 'Quote', detail: 'Detail', punchline: 'Punchline',
      readyPrompt: 'Ready Prompt', score: 'Score', band: 'Band', reviewedOn: 'Reviewed On',
    };

    const originalIdea = data.originalIdea || data.idea;
    const repairedIdea = data.repairedIdea;

    let fieldsHtml = '';
    const allKeys = new Set([...Object.keys(originalIdea), ...Object.keys(repairedIdea)]);
    for (const key of allKeys) {
      const isChanged = comp.changedFields.includes(key);
      const origVal = originalIdea[key];
      const repVal = repairedIdea[key];
      const origDisplay = Array.isArray(origVal) ? JSON.stringify(origVal) : String(origVal || '');
      const repDisplay = Array.isArray(repVal) ? JSON.stringify(repVal) : String(repVal || '');
      fieldsHtml += `
        <div class="repair-field ${isChanged ? 'changed' : 'unchanged'}">
          <div class="repair-field-label">
            ${fieldLabels[key] || key}
            <span class="repair-field-badge ${isChanged ? 'badge-changed' : 'badge-unchanged'}">
              ${isChanged ? 'CHANGED' : 'UNCHANGED'}
            </span>
          </div>
          <div style="display:flex; gap:0.5rem;">
            <div style="flex:1;">
              <div style="font-size:0.7rem;color:var(--text-muted);">Original</div>
              <div class="repair-field-value">${this.escapeHtml(origDisplay)}</div>
            </div>
            <div style="flex:1;">
              <div style="font-size:0.7rem;color:var(--text-muted);">Repaired</div>
              <div class="repair-field-value">${this.escapeHtml(repDisplay)}</div>
            </div>
          </div>
        </div>
      `;
    }

    // Issues resolved / remaining
    const origCritical = orig.criticalFindings || [];
    const origMajor = orig.majorFindings || [];
    const origMinor = orig.minorFindings || [];
    const origSuggestions = orig.suggestions || [];
    const repCritical = rep.criticalFindings || [];
    const repMajor = rep.majorFindings || [];
    const repMinor = rep.minorFindings || [];
    const repSuggestions = rep.suggestions || [];

    const issuesHtml = `
      <div class="repair-issues-list">
        <h4>Issues Summary</h4>
        <div class="repair-issue resolved">
          <div class="repair-issue-header">
            <span class="repair-issue-title">Critical Issues</span>
            <span class="repair-issue-severity sev-critical-badge">Critical</span>
          </div>
          <div class="repair-issue-detail">Original: ${origCritical.length} → Repaired: ${repCritical.length}</div>
          <div class="repair-issue-status">${repCritical.length === 0 ? 'All resolved' : repCritical.length + ' remaining'}</div>
        </div>
        <div class="repair-issue ${repMajor.length === 0 ? 'resolved' : 'remaining'}">
          <div class="repair-issue-header">
            <span class="repair-issue-title">Major Issues</span>
            <span class="repair-issue-severity sev-major-badge">Major</span>
          </div>
          <div class="repair-issue-detail">Original: ${origMajor.length} → Repaired: ${repMajor.length}</div>
          <div class="repair-issue-status">${repMajor.length === 0 ? 'All resolved' : repMajor.length + ' remaining'}</div>
        </div>
        <div class="repair-issue ${repMinor.length === 0 ? 'resolved' : 'remaining'}">
          <div class="repair-issue-header">
            <span class="repair-issue-title">Minor Issues</span>
            <span class="repair-issue-severity sev-minor-badge">Minor</span>
          </div>
          <div class="repair-issue-detail">Original: ${origMinor.length} → Repaired: ${repMinor.length}</div>
          <div class="repair-issue-status">${repMinor.length === 0 ? 'All resolved' : repMinor.length + ' remaining'}</div>
        </div>
        <div class="repair-issue ${repSuggestions.length === 0 ? 'resolved' : 'remaining'}">
          <div class="repair-issue-header">
            <span class="repair-issue-title">Suggestions</span>
            <span class="repair-issue-severity sev-suggestion-badge">Suggestion</span>
          </div>
          <div class="repair-issue-detail">Original: ${origSuggestions.length} → Repaired: ${repSuggestions.length}</div>
          <div class="repair-issue-status">${repSuggestions.length === 0 ? 'All resolved' : repSuggestions.length + ' remaining'}</div>
        </div>
      </div>
    `;

    const canSave = data.canSave !== false;
    const saveButton = canSave
      ? `<button class="btn btn-primary" onclick="app.saveRepairedIdea('${repairMode}')">Save Repaired Idea</button>`
      : `<button class="btn btn-primary" disabled style="opacity:0.6;cursor:not-allowed;">Cannot Save — Critical Issues Remain</button>`;

    const fixedIssuesHtml = fixedIssues.length > 0
      ? `<div class="repair-issues-list">
        <h4 style="color:var(--success);">Issues Fixed (${repairMode} mode)</h4>
        ${fixedIssues.map(f => `<div class="repair-issue resolved">
          <div class="repair-issue-detail">${this.escapeHtml(f)}</div>
        </div>`).join('')}
      </div>`
      : '';

    const unresolvedIssuesHtml = unresolvedIssues.length > 0
      ? `<div class="repair-issues-list">
        <h4 style="color:var(--warning);">Issues Still Unresolved</h4>
        ${unresolvedIssues.map(f => `<div class="repair-issue remaining">
          <div class="repair-issue-detail">${this.escapeHtml(f)}</div>
        </div>`).join('')}
      </div>`
      : '';

    body.innerHTML = `
      <div class="repair-state ${canSave ? 'success' : 'confirm'}">
        <strong>Repair Mode:</strong> ${modeLabel} | <strong>Changed fields:</strong> ${comp.changedFields.length} | <strong>Unchanged fields:</strong> ${comp.unchangedFields.length}<br>
        ${canSave ? 'All critical safety gates pass. Ready to save.' : 'Cannot save — critical safety gates still fail. Review and repair again.'}
      </div>
      ${fixedIssuesHtml}
      ${unresolvedIssuesHtml}
      <div class="repair-comparison">
        <div class="repair-column original">
          <h4>Original Idea</h4>
          <div class="repair-score-table">
            <tr><th>Metric</th><th>Original</th></tr>
            <tr><td>Overall Score</td><td>${orig.overallScore || 'N/A'}/100</td></tr>
            <tr><td>Verdict</td><td>${orig.verdict || 'N/A'}</td></tr>
            <tr><td>Critical</td><td>${origCritical.length}</td></tr>
            <tr><td>Major</td><td>${origMajor.length}</td></tr>
            <tr><td>Minor</td><td>${origMinor.length}</td></tr>
            <tr><td>Suggestions</td><td>${origSuggestions.length}</td></tr>
          </div>
        </div>
        <div class="repair-column repaired">
          <h4>AI-Repaired Idea</h4>
          <div class="repair-score-table">
            <tr><th>Metric</th><th>Repaired</th></tr>
            <tr><td>Overall Score</td><td><span class="repair-score-change ${scoreChangeClass}">${scoreChangeSign}${rep.overallScore || 'N/A'}</span>/100</td></tr>
            <tr><td>Verdict</td><td>${rep.verdict || 'N/A'}</td></tr>
            <tr><td>Critical</td><td>${repCritical.length}</td></tr>
            <tr><td>Major</td><td>${repMajor.length}</td></tr>
            <tr><td>Minor</td><td>${repMinor.length}</td></tr>
            <tr><td>Suggestions</td><td>${repSuggestions.length}</td></tr>
          </div>
        </div>
      </div>
      <h4 style="margin-top:1rem;">Field-by-Field Comparison</h4>
      ${fieldsHtml}
    `;

    footer.innerHTML = `
      ${saveButton}
      <button class="btn btn-secondary" onclick="app.discardRepair()">Discard Changes</button>
    `;

    document.getElementById('repairModal').style.display = 'flex';
  },

  closeRepairModal() {
    document.getElementById('repairModal').style.display = 'none';
    this.repairModalData = null;
    this.repairState = null;
  },

  async saveRepairedIdea(repairMode = 'offline') {
    if (!this.repairModalData || !this.repairModalData.repairedIdea) return;

    const { ideaId, repairedIdea, originalEvaluation, repairedEvaluation, comparison } = this.repairModalData;

    try {
      const res = await fetch(`${API_BASE}/api/ideas/${ideaId}/repair/save`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          repairedIdea,
          originalEvaluation,
          repairedEvaluation,
          comparison,
          repairMode,
        }),
      });

      if (!res.ok) {
        const err = await res.json().catch(() => ({}));
        throw new Error(err.error || `Save failed (${res.status})`);
      }

      const result = await res.json();
      this.closeRepairModal();
      this.showToast(result.message, 'success');

      // Refresh data from the updated JSON
      await this.loadIdeas();
      await this.loadRatings();
      await this.loadFreshness();
      this.renderDashboard();
      this.renderLibrary();
    } catch (e) {
      this.showToast('Save failed: ' + e.message, 'error');
    }
  },

  discardRepair() {
    this.closeRepairModal();
    this.showToast('Repair discarded. Original idea unchanged.', 'info');
  },

  async showRepairHistory(ideaId) {
    try {
      const res = await fetch(`${API_BASE}/api/ideas/${ideaId}/repair/history`);
      if (!res.ok) throw new Error('Failed to load repair history');
      const data = await res.json();

      const body = document.getElementById('repairHistoryBody');
      if (data.history.length === 0) {
        body.innerHTML = '<p>No repair history for this idea.</p>';
      } else {
        body.innerHTML = `
          <ul class="repair-history-list">
            ${data.history.map(h => `
              <li class="repair-history-item">
                <div class="repair-history-header">
                  <span class="repair-history-date">${new Date(h.repairTimestamp).toLocaleString()}</span>
                  <span class="repair-history-score">${h.originalScore} → ${h.repairedScore}</span>
                </div>
                <div style="font-size:0.85rem; margin-bottom:0.5rem;">
                  <strong>Verdict:</strong> ${h.originalVerdict} → ${h.repairedVerdict}<br>
                  <strong>Changed fields:</strong> ${h.changedFields?.length || 0}
                </div>
                <div class="repair-history-actions">
                  <button class="btn btn-secondary" onclick="app.restoreFromHistory('${ideaId}', '${h.repairTimestamp}')">Restore This Version</button>
                </div>
              </li>
            `).join('')}
          </ul>
        `;
      }

      document.getElementById('repairHistoryModal').style.display = 'flex';
    } catch (e) {
      this.showToast('Failed to load repair history: ' + e.message, 'error');
    }
  },

  closeRepairHistoryModal() {
    document.getElementById('repairHistoryModal').style.display = 'none';
  },

  async restoreFromHistory(ideaId, timestamp) {
    if (!confirm('Restore this previous version? This will overwrite the current idea in content_ideas.json.')) return;

    try {
      const res = await fetch(`${API_BASE}/api/ideas/${ideaId}/repair/restore`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ historyTimestamp: timestamp }),
      });

      if (!res.ok) {
        const err = await res.json().catch(() => ({}));
        throw new Error(err.error || `Restore failed (${res.status})`);
      }

      const result = await res.json();
      this.closeRepairHistoryModal();
      this.showToast(result.message, 'success');

      await this.loadIdeas();
      await this.loadRatings();
      await this.loadFreshness();
      this.renderDashboard();
      this.renderLibrary();
    } catch (e) {
      this.showToast('Restore failed: ' + e.message, 'error');
    }
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
