# CAFA-eval-lite
A lite Matlab toolbox for evaluating protein function predictors (according to CAFA protocol)

## Basic data structure
There are two types of basic data structures used widely in this toolbox:

### Ontology
The ontology structure consists of the following fields:
* `term`, which is a `struct` array having `id` and `name` corresponding to ontology term id and description of each term.
* `rel_code`, is a cell array storing the types of relation used in this structure, for example `{'is_a', 'part_of'}`.
* `DAG`, a sparse integer matrix encoding the relations between terms, i.e., `DAG(i, j) = 1` indicates term `i` and `j` has the type `1` relation, while those relation types are encoded in `rel_code`.
* `alt_list`, is a mapping table between alternative term id and approved term id.
* `date`, the date when this ontology structure is created.

#### To build an ontology structure from an OBO file, GO for example
```matlab
pfp_ontbuild('/path/to/obofile');
```

### Ontology annotation/prediction
The structure that represents a set of annotation (usually experimental) using a
specific ontology:
* `object`, is a set of objects having annotations (usually proteins or genes)
* `ontology`, an ontology structure associated with this annotation set.
* `annotation`, a sparse logical matrix indicating if object `i` is annotated with term `j`. Note that `i` is the i-th entry in `object` while `j` is the j-th term of `{ontology.term.id}`.
* `date`, is the date when this structure is created.

Note that there is a similar structure representing a predictor's output. The only difference is that the `annotation` field is replaced by `score`, which is a sparse real number matrix (having scores between [0, 1]) having its prediction scores.

#### To build an annotation structure
```matlab
pfp_oabuild(ont, '/path/to/plain-text-annotation', '/more/files', ...);
```
where `ont` is an ontology structure built using `pfp_ontbuild` and the following plain-text annotation files should have only two columns: 1) sequence (protein/gene) ID and 2) annotated term ID.

## Evaluation
Considered as a *multi-label learning (MLL)* problem, protein functionprediction requires a method to predict a score for an instance (protein orgene) for every possible label. Therefore, evaluating such a prediction resultsin comparing a prediction matrix and a "ground-truth" annotation matrix, both ofwhich having size `n`-by-`m`, where `n` is the number of instances and `m` isthe number of labels (terms in an ontology).

Generally, there are two types of evaluation schemes: 1) sequence-centric and 2) term-centric. The former calculates a performance measure for each row first and then combines those results to get an overall performance measure; while the latter calculates in a column-major manner followed by the combination step.

One needs to specify which metric to use for each row (or column) and which method to use when combining those measures. In CAFA2, we used (weighted) F-measure, and (normalized) semantic distance for sequence-centric evaluation, and AUC is used for term-centric evaluation. And in both schemes, combination was done simply by averaging.

## Baseline methods
The lite toolbox also contains functions to build the two baseline methods used in CAFA evaluation, i.e., Naive and BLAST.

* Naive predictions can be created by using `pfp_naive.m` which loads an annotation structure and predicts a query protein according to the annotation frequency.

* BLAST prediction can be created by using `pfp_blast.m`. The function depends on an extra structure created from `pfp_importblastp.m` which, as the name indicates, imports output results from the `blastp` program (tested on v2.2.28+).  (Note that we usually BLAST the test set proteins against the annotated training set proteins to obtain those BLAST hits.)

# License
The source code of this project is licensed under the MIT license.
