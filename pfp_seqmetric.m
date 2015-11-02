function [m] = pfp_seqmetric(target, pred, oa, metric, varargin)
%PFP_SEQMETRIC Sequence-centered metric
% {{{
%
% [m] = PFP_SEQMETRIC(target, pred, oa, metric, varargin);
%
%   Computes the averaged sequence-centered metric.
%
% Input
% -----
% [cell]
% target: A list of target objects.
%         For those target sequences that are not in pred.object, their 
%         predicted associtated scores for each term will be 0.00, as if they
%         are not predicted.
%
% [struct]
% pred:   The prediction structure.
%
% [struct]
% oa:     The reference structure.
%
% [char]
% metric:   The metric need to be averaged. Must be one of the following:
%           'pr'    - averaged precision-recall curve
%           'wpr'   - averaged weighted precision-recall curve
%           'rm'    - averaged RU-MI curve
%           'nrm'   - averaged normalized RU-MI curve
%           'fmax'  - maximum F-measure
%           'wfmax' - maximum weighted F-measure
%           'smin'  - minimum semantic distance
%           'nsmin' - minimum normalized semantic distance
%
% (optional) Name-Value pairs
% [double]
% 'tau'     An array of thresholds.
%           default: 0.00 : 0.01 : 1.00 (i.e. 0.00, 0.01, ..., 0.99, 1.00)
%
% [logical or char]
% 'toi'     A binary vector indicating "terms of interest".
%           Note that the following special short-hand tokens are also allowed.
%           'all'       - all terms
%           'noroot'    - exclude root term
%           default: 'noroot'
%
% [double or char]
% 'w'       A weight vector over terms.
%           Note that the following special short-hand tokens are also allowed.
%           'equal'     - equal weights, regular confusion matrix.
%           'eia'       - weighted by estimated information content.
%           default: 'equal'
%
% [double]
% 'beta'    Used in F_{beta}-measure.
%           default: 1
%
% [double]
% 'order'   The order of semantic distance. (sequence-centered only)
%           default: 2
%
% [logical]
% 'Q'       An n-by-1 indicator of qualified predictions. It won't affect
%           the result in 'full' evaluation mode, however, in the 'partial'
%           mode, only rows corresponding to TRUE bits are averaged.
%           default: 'auto' (means it will be determined automatically)
%
%           Note: this parameter is suggested to be determined automatically
%           by pfp_seqcm.m, see the returning value from this function, in
%           particular, field 'npp'. If one need to manually specify this
%           column, make sure it's of the same dimension as 'target'.
%
% [char]
% evmode:   The mode of evaluation. Only effective in "sequence-centered"
%           evaluation, i.e., returned by pfp_seqcm.m rather than pfp_termcm.m.
%           (indeed, 'evmode' has to be decided when calling pfp_termcm.m)
%           '1', 'full'     - averaged over the entire benchmark sets.
%                             missing prediction are treated as 0.
%           '2', 'partial'  - averaged over the predicted subset (partial).
%
%           default: 'full'
%
% [char]
% avgmode:  The mode of averaging.
%           'macro' - macro-average, compute the metric over each confusion
%                     matrix and then average the metric.
%           'micro' - micro-average, average the confusion matrix, and then
%                     compute the metric.
%
%           default: 'macro'
%
% Output
% ------
% [cell]
% m:        The resulting metric of interest.
%
% Dependency
% ----------
%[>]pfp_roottermidx.m
%[>]pfp_seqcm.m
%[>]pfp_cmavg.m
% }}}

  % check basic inputs {{{
  if nargin < 4
    error('pfp_seqmetric:InputCount', 'Expected >= 4 inputs.');
  end

  % check the 1st input 'target' {{{
  validateattributes(target, {'cell'}, {'nonempty'}, '', 'target', 1);
  % }}}

  % check the 2nd input 'pred' {{{
  validateattributes(pred, {'struct'}, {'nonempty'}, '', 'pred', 2);
  % }}}

  % check the 3rd input 'oa' {{{
  validateattributes(oa, {'struct'}, {'nonempty'}, '', 'oa', 3);
  if numel(pred.ontology.term) ~= numel(oa.ontology.term) || ~all(strcmp({pred.ontology.term.id}, {oa.ontology.term.id}))
    error('pfp_seqmetric:InputErr', 'Ontology mismatch.');
  end
  % }}}

  % check the 4th input 'metric' {{{
  valid_metrics = {'pr', 'wpr', 'rm', 'nrm', 'fmax', 'wfmax', 'smin', 'nsmin'};
  metric = validatestring(metric, valid_metrics);
  % }}}
  % }}}

  % check optional inputs {{{
  p = inputParser;

  defaultTAU      = 0.00 : 0.01 : 1.00;
  defaultTOI      = 'noroot';
  defaultW        = 'equal';
  defaultBETA     = 1.0;
  defaultORDER    = 2.0;
  defaultQ        = 'auto';
  defaultEV_MODE  = 'full';
  defaultAVG_MODE = 'macro';

  valid_evmodes   = {'1', '2', 'full', 'partial'};
  valid_avgmodes  = {'macro', 'micro'};

  addParameter(p, 'tau', defaultTAU, @(x) validateattributes(x, {'double'}, {'vector', '>=', 0, '<=', 1}));
  addParameter(p, 'toi', defaultTOI, @(x) validateattributes(x, {'logical', 'char'}, {'nonempty'}));
  addParameter(p, 'w', defaultW, @(x) validateattributes(x, {'double', 'char'}, {'nonempty'}));
  addParameter(p, 'beta', defaultBETA, @(x) validateattributes(x, {'double'}, {'real', 'positive'}));
  addParameter(p, 'order', defaultORDER, @(x) validateattributes(x, {'double'}, {'real', 'positive'}));
  addParameter(p, 'Q', defaultQ, @(x) validateattributes(x, {'char', 'logical'}, {}));
  addParameter(p, 'evmode', defaultEV_MODE, @(x) any(strcmpi(x, valid_evmodes)));
  addParameter(p, 'avgmode', defaultAVG_MODE, @(x) any(strcmpi(x, valid_avgmodes)));

  parse(p, varargin{:});
  % }}}

  % call to pfp_seqcm {{{
  % determine 'w' "smartly"
  if ismember(metric, {'wpr', 'wfmax', 'rm', 'nrm', 'smin', 'nsmin'}) && strcmp(p.Results.w, defaultW)
    w = 'eia';
  else
    w = p.Results.w;
  end
    
  cm = pfp_seqcm(target, pred, oa, ...
    'tau', p.Results.tau, ...
    'toi', p.Results.toi, ...
    'w',   w ...
  );
  % }}}

  % call to pfp_cmavg {{{
  % parse Q
  if ischar(p.Results.Q) && strcmp(p.Results.Q, 'auto')
    Q = (cm.npp > 0);
  elseif islogical(p.Results.Q) && numel(p.Results.Q) == numel(target)
    Q = p.Results.Q;
  else
    error('pfp_seqmetric:InvalidQ', 'Q must be either ''auto'' or a logical vector of the same length of ''target''.')
  end
    
  % translate metrics
  metric_map = {...
    'pr',    'pr'; ...
    'wpr',   'wpr'; ...
    'rm',    'rm'; ...
    'nrm',   'nrm'; ...
    'fmax',  'pr'; ...
    'wfmax', 'wpr'; ...
    'smin',  'rm'; ...
    'nsmin', 'nrm' ...
  };
  met = metric_map{strcmp(metric_map(:, 1), metric), 2};
  m = pfp_cmavg(cm, met, ...
    'beta',     p.Results.beta, ...
    'order',    p.Results.order, ...
    'Q',        Q, ...
    'evmode',   p.Results.evmode, ...
    'avgmode',  p.Results.avgmode ...
  );
  % }}}

  % post-processing {{{
  if ismember(metric, {'fmax', 'wfmax'})
    m = pfp_fmaxc(cell2mat(reshape(m, [], 1)), cm.tau);
  elseif ismember(metric, {'smin', 'nsmin'})
    m = pfp_sminc(cell2mat(reshape(m, [], 1)), cm.tau);
  else
    m = cell2mat(reshape(m, [], 1));
  end
  % }}}
return
