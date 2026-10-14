# Orders and higher classification of vascular plant families

Orders of the families of vascular plants (angiosperms, gymnosperms and
pteridophytes). For angiosperms, orders and higher levels of
classification follow the fourth update of the Angiosperm Phylogeny
Group (APG IV,
[doi:10.1111/boj.12385](https://doi.org/10.1111/boj.12385) ); higher
levels are the names of nodes of the consensus tree (Figure 1 of APG
IV). Orders of gymnosperms and pteridophytes were obtained from the
website of the Missouri Botanical Garden. Used by
[`WFO.family()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.browse.md)
and
[`WFO.browse()`](https://jeromechave.github.io/WorldFloraFast/reference/WFO.browse.md).

## Usage

``` r
vascular.families
```

## Format

A data.frame with 476 rows and 10 columns:

- Group:

  Group.

- Family.ID:

  Unique ID for each family; for angiosperms, as in APG IV.

- Family:

  Name of the family.

- Family.taxonID:

  taxonID in the World Flora Online.

- Order:

  Name of the order.

- Order.taxonID:

  taxonID in the World Flora Online.

- Node.1:

  Name of the node in the consensus tree.

- Node.2:

  Name of the node, nested within Node.1.

- Node.3:

  Name of the node, nested within Node.2.

- Node.4:

  Name of the node, nested within Node.3.

## Source

The Angiosperm Phylogeny Group et al. (2016). An update of the
Angiosperm Phylogeny Group classification for the orders and families of
flowering plants: APG IV. Botanical Journal of the Linnean Society 181:
1-20. [doi:10.1111/boj.12385](https://doi.org/10.1111/boj.12385)

## Examples

``` r
data(vascular.families)
head(vascular.families[, c("Family", "Order", "Node.1")])
#>              Family            Order Node.1
#> 1     Amborellaceae     Amborellales       
#> 2     Hydatellaceae      Nymphaeales       
#> 3       Cabombaceae      Nymphaeales       
#> 4      Nymphaeaceae      Nymphaeales       
#> 5 Austrobaileyaceae Austrobaileyales       
#> 6      Trimeniaceae Austrobaileyales       
```
