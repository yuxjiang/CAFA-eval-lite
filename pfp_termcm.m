function [cm] = pfp_termcm(target, pred, oa, ev_mode, varargin)
%PFP_TERMEVAL Term-centric confusion matrices
% {{{
%
% [cm] = PFP_TERMCM(target, pred, oa, ev_mode, varargin);
%
%   Calculate term-centric confusion matrices. It computes k matrices for each
%   'target' sequence, where 'k' is the number of thresholds.
%
% Note
% ----
% This function assumes the predicted scores have been normalized to be within
% the range [0, 1].
%
% Input
% -----
% [cell]
% target:   A list of target objects.
%           For those target sequences that are not in pred.object, their
%           predicted associtated scores for each term will be 0.00, as if they
%           are not predicted.
%
% [struct]
% pred:     The prediction structure.
%
% [struct]
% oa:       The reference structure.
%
% [char]
% ev_mode:  The mode of evaluation.
%           '1', 'full'     - averaged over the entire benchmark sets.
%                               missing prediction are treated as 0.
%           '2', 'partial'  - averaged over the predicted subset (partial).
%
% (optional) Name-Value pairs
% [double]
% 'tau'     An array of thresholds.
%           default: 0.00 : 0.01 : 1.00 (i.e. 0.00, 0.01, ..., 0.99, 1.00)
%
% Output
% ------
% [struct]
% cm: The structure of results.
%
%     [char]
%     .centric    'term'
%
%     [cell]
%     .object     A n-by-1 array of (char) object ID.
%
%     [struct]
%     .term       A 1-by-m array of (char) term ID.
%
%     [double]
%     .tau        A 1-by-k array of thresholds.
%
%     [struct]
%     .cm         An m-by-k struct array of confusion matrices.
%
%     [double]
%     .npp        An 1-by-m array of number of positive predictions for
%                 each term.
%
%     [char]
%     .date       The date whtn this evaluation is performed.
%
% Dependency
% ----------
%[>]pfp_predproj.m
%[>]pfp_oaproj.m
%[>]pfp_confmat.m
%
% See Also
% --------
%[>]pfp_oabuild.m
% }}}

  % check basic inputs {{{
  if nargin < 4
    error('pfp_termcm:InputCount', 'Expected >= 4 inputs.');
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
    error('pfp_termeval:InputErr', 'Ontology mismatch.');
  end
  % }}}

  % check the 4th input 'ev_mode' {{{
  ev_mode = validatestring(ev_mode, {'1', 'full', '2', 'partial'}, '', 'ev_mode', 4);
  % }}}
  % }}}

  % parse and check extra inputs {{{
  p = inputParser;

  defaultTAU   = 0.00 : 0.01 : 1.00;

  addParameter(p, 'tau', defaultTAU, @(x) validateattributes(x, {'double'}, {'vector', '>=', 0, '<=', 1}));

  parse(p, varargin{:})
  % }}}

  % align 'pred' and 'oa' onto the given target list {{{
  if ismember(ev_mode, {'2', 'partial'})
    npp_seq = sum(pred.score > 0.0, 2);
    pred.object(npp_seq > 0);
    target = intersect(pred.object(npp_seq > 0), target);
  end
  pred = pfp_predproj(pred, target, 'object');
  oa   = pfp_oaproj(oa, target, 'object');
  % }}}

  % prepare for output {{{
  % positive annotation
  pos_anno = any(oa.annotation, 1);

  % construct prediction matrix and reference (ground truth) matrix.
  P = pred.score(:, pos_anno);
  T = oa.annotation(:, pos_anno);

  cm.centric = 'term';
  cm.object  = pred.object;
  cm.term    = reshape({pred.ontology.term(pos_anno).id}, 1, []);
  cm.tau     = p.Results.tau;

  m = size(P, 2);

  cm.npp = reshape(full(sum(P > 0.0, 1)), [], 1);
  cm.cm  = cell(m, 1);

  for i = 1 : m
    cm.cm{i} = pfp_confmat(P(:, i), T(:, i), p.Results.tau);
  end
  cm.cm   = cell2mat(cm.cm);
  cm.date = date;
  % }}}
return

% -------------
% Yuxiang Jiang (yuxjiang@indiana.edu)
% Department of Computer Science
% Indiana University Bloomington
% Last modified: Wed 21 Oct 2015 06:24:14 PM E
