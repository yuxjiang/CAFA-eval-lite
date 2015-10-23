% load ontology structure: MFO
% This structure can also be produced by pfp_ontbuild.m with an obo file.
load('./MFO.mat', 'MFO');

% load ontology annotation structure ("ground-truth"): oa
% This structure can also be produced by pfp_oabuild.m with an ontology
% structure and plain-text annotation files, see pfp_oabuild.m for details.
load('./MFO_annotation.mat', 'oa');

% load predictions
% The prediction file should follow the CAFA protocal, see cafa_import.m for
% more details.
pred = cafa_import('./BLAST_prediction.txt', MFO);

% load a list of benchmark sequence id
% Note: sequence ID used in (ground-truth) annotations, predictions as well as
% benchmark list should be compatible with each other.
benchmark = pfp_loaditem('./MFO_benchmark.txt', 'char');

% Now, suppose we'd like to do an "sequence-centric" evaluation, and calculate
% precision-recall curves.

% make the confusion matrix structure
cm = pfp_seqcm(benchmark, pred, oa);

% convert the cm structure to metrics of interest, here 'precision-recall'
seq_pr = pfp_convcmstruct(cm, 'pr');

% Now, 'seq_pr.metric' should have 101 precision-recall pairs (points) corresp.
% to 101 thresholds from 0.00 to 1.00 at stepsize = 0.01;
