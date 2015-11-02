function [m] = pfp_cmavg(cm, metric, varargin)
%PFP_CMAVG Confusion matrix average
% {{{
%
% [m] = PFP_CMAVG(cm, metric, varargin);
%
%   Computes the averaged metric from confusion matrices.
%
% Input
% -----
% [struct]
% cm:       The confusion matrix structure.
%           (It can be obtained from pfp_seqcm.m, or pfp_termcm.m)
%
% [char]
% metric:   The metric need to be averaged. Must be one of the following:
%           'pr'    - precision, recall
%           'wpr'   - weighted precision, recall
%         * 'rm'    - RU, MI
%         * 'nrm'   - normalized RU, MI
%           'f'     - F-measure
%           'wf'    - weighted F-measure
%         * 'sd'    - semantic distance
%         * 'nsd'   - normalized semantic distance
%           'ss'    - sensitivity, 1 - specificity (points on ROC)
%           'acc'   - accuracy
%
%         * Note: starred (*) metrics are only available in "sequence-centered"
%           evaluation. Since information accretion makes no sense in
%           "term-centered" evaluation model.
%
%           Also, weighted metrics (e.g. wpr) is not available for now in
%           "term-centered" evaluation mode, see pfp_termcm.m.
%
% (optional) Name-Value pairs
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
%           default: cm.npp > 1 (at least one positive predictions, see
%           pfp_seqcm.m or pfp_termcm.m for details)
%
% [char]
% ev_mode:  The mode of evaluation. Only effective in "sequence-centered"
%           evaluation, i.e., returned by pfp_seqcm.m rather than pfp_termcm.m.
%           (indeed, 'ev_mode' has to be decided when calling pfp_termcm.m)
%           '1', 'full'     - averaged over the entire benchmark sets.
%                             missing prediction are treated as 0.
%           '2', 'partial'  - averaged over the predicted subset (partial).
%
%           default: 'full'
%
% [char]
% avg_mode: The mode of averaging.
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
% m:        The 1-by-k averaged metric.
%
% Dependency
% ----------
%[>]pfp_cmmetric.m
%
% See Also
% --------
%[>]pfp_seqcm.m
%[>]pfp_termcm.m
% }}}

  % check inputs {{{
  if nargin < 2
    error('pfp_cmavg:InputCount', 'Expected >= 2 inputs.');
  end

  % check the 1st input 'cm' {{{
  validateattributes(cm, {'struct'}, {'nonempty'}, '', 'cm', 1);
  cms = cm.cm;
  [n, k] = size(cms);
  % }}}

  % check the 2nd input 'metric' {{{
  validatestring(metric, {'pr', 'wpr', 'rm', 'nrm', 'f', 'wf', 'sd', 'nsd', 'ss', 'acc'}, '', 'metric', 2);
  % }}}
  % }}}

  % parse additional inputs {{{
  p = inputParser;

  defaultBETA     = 1;
  defaultORDER    = 2;
  defaultQ        = reshape(cm.npp > 0, [], 1);
  defaultEV_MODE  = 'full';
  defaultAVG_MODE = 'macro';

  valid_ev_modes  = {'full', 'partial'};
  valid_avg_modes = {'macro', 'micro'};

  addParameter(p, 'beta', defaultBETA, @(x) validateattributes(x, {'double'}, {'real', 'positive'}));
  addParameter(p, 'order', defaultORDER, @(x) validateattributes(x, {'double'}, {'real', 'positive'}));
  addParameter(p, 'Q', defaultQ, @(x) validateattributes(x, {'logical'}, {'ncols', 1, 'numel', n}));
  % validatestring doesn't work for 'ev_mode' for some reason ...
  % addParameter(p, 'ev_mode', defaultEV_MODE, @(x) validatestring(x, valid_ev_modes));
  addParameter(p, 'ev_mode', defaultEV_MODE, @(x) ismember(x, valid_ev_modes));
  addParameter(p, 'avg_mode', defaultAVG_MODE, @(x) ismember(x, valid_avg_modes));

  parse(p, varargin{:});
  % }}}

  % sanity check for sequence-centered {{{
  if strcmp(cm.centric, 'term') && ismember(metric, {'rm', 'nrm', 'sd', 'nsd'})
    error('pfp_cmavg:IncompatibleInput', 'metric is not available in term-centered evaluation.');
  end
  % }}}

  % select rows to average according to 'ev_mode' and 'Q' {{{
  switch p.Results.ev_mode
  case {'1', 'full'}
    % use the full matrix, nop
  case {'2', 'partial'}
    cms = cms(p.Results.Q, :);
  otherwise
    % nop
  end
  % }}}

  % averaging {{{
  m = cell(1, k);
  switch p.Results.avg_mode
  case 'macro'
    for i = 1 : k
      cm = [reshape(full([cms(:, i).TN]), [], 1), ...
            reshape(full([cms(:, i).FP]), [], 1), ...
            reshape(full([cms(:, i).FN]), [], 1), ...
            reshape(full([cms(:, i).TP]), [], 1)];
      raw_m = pfp_cmmetric(cm, metric, 'beta', p.Results.beta, 'order', p.Results.order);
      m{i} = zeros(1, size(raw_m, 2));
      for j = 1 : size(raw_m, 2)
        collect = raw_m(:, j);
        m{i}(j) = mean(collect(~isnan(collect)));
      end
    end
  case 'micro'
    for i = 1 : k
      cm = [full(mean([cms(:, i).TN])), ...
            full(mean([cms(:, i).FP])), ...
            full(mean([cms(:, i).FN])), ...
            full(mean([cms(:, i).TP]))];
      m{i} = pfp_cmmetric(cm, metric, 'beta', p.Results.beta, 'order', p.Results.order);
    end
  otherwise
    % nop
  end
  % }}}
return

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University Bloomington
% Last modified: Mon 02 Nov 2015 02:38:13 PM E
