

qp_parse_graph <- function(text) {
    tokens <- c(
        root        = "root",
        label       = "label",
        edge        = "edge",
        admix       = "admix",
        number      = "-?\\d*\\.?\\d+",
        name        = "\\w+",
        newline     = "\\n",
        whitespace  = "\\s+"
    )


    token_stream <- minilexer::lex(text, tokens)
    token_stream <- token_stream[
        !(names(token_stream) %in% c('whitespace', 'newline'))
        ]
    lexer <- minilexer::TokenStream$new(token_stream)

    root <- NULL
    edges <- list()
    admixtures <- list()

    parse_root <- function() {
        lexer$consume_token(type = "root")
        root <<- lexer$consume_token(type = "name")
    }

    parse_label <- function() {
        lexer$consume_token(type = "label")
        lexer$consume_token(type = "name")
        lexer$consume_token(type = "name")
    }

    parse_edge <- function() {
        lexer$consume_token(type = "edge")
        edge_name <- lexer$consume_token(type = "name")
        parent <- lexer$consume_token(type = "name")
        child <- lexer$consume_token(type = "name")
        edge <- c(child = child, parent = parent, NA)
        edges[[length(edges) + 1]] <<- edge
    }

    parse_admixture <- function() {
        lexer$consume_token(type = "admix")
        admixed <- lexer$consume_token(type = "name")
        parent_1 <- lexer$consume_token(type = "name")
        parent_2 <- lexer$consume_token(type = "name")
        alpha <- lexer$consume_token(type = "number")
        lexer$consume_token(type = "number")
        admixture <- c(
            admixed = admixed,
            parent_1 = parent_1,
            parent_2 = parent_2,
            alpha = as.numeric(alpha) / 100 # from percentages to fractions
        )
        admixtures[[length(admixtures) + 1]] <<- admixture
    }

    while (!lexer$end_of_stream) {
        switch(lexer$current_type(),
               "root" = parse_root(),
               "label" = parse_label(),
               "edge" = parse_edge(),
               "admix" = parse_admixture()
        )
    }

    list(root = root, edges = edges, admixtures = admixtures)
}

qp_get_edges <- function(graph_info) {
    edges <- graph_info$edges
    no_edges <- length(edges)
    admixtures <- graph_info$admixtures
    no_admixtures <- length(admixtures)

    n <- no_edges + 2 * no_admixtures
    tbl <- character(length = n * 3)
    dim(tbl) <- c(n, 3)

    for (i in seq_along(edges)) {
        tbl[i,] <- edges[[i]]
    }
    for (i in seq_along(admixtures)) {
        x <- admixtures[[i]]
        child = x[1]
        parent1 = x[2]
        parent2 = x[3]
        prop <- paste0(child, "_", parent1)
        other_prop <- paste0("(1 - ", prop, ")")
        tbl[no_edges + 2*i - 1,] <- c(child, parent1, prop)
        tbl[no_edges + 2*i,] <- c(child, parent2, other_prop)
    }
    tbl
}

qp_get_nodes <- function(edges) {
    inner_nodes <- edges[,2] %>% unique
    leaves <- setdiff(edges[,1], inner_nodes)
    list(inner_nodes = inner_nodes, leaves = leaves)
}


qp_get_admixture_proportions <- function(graph_info) {

    admixtures <- graph_info$admixtures
    children <- c() ; parents <- c() ; props <- c()

    for (i in seq_along(admixtures)) {
        vars <- admixtures[[i]]
        children[length(children) + 1] <- vars["admixed"]
        parents[length(parents) + 1] <- vars["parent_1"]
        props[length(props) + 1] <- as.numeric(vars["alpha"])

    }
    prop_vars <- paste0(children, "_", parents)
    if (length(props) > 0)
        names(props) <- prop_vars
    props
}

#' Import a qpGraph file into an admixturegraph object
#'
#' @param text Text containing the graph description.
#' @return An admixturegraph object
#' @import admixturegraph
#' @export
read_qpgraph <- function(text) {
    graph_info <- qp_parse_graph(text)
    edges <- qp_get_edges(graph_info)
    nodes <- qp_get_nodes(edges)
    admix_props <- qp_get_admixture_proportions(graph_info)
    graph <- agraph(nodes$leaves, nodes$inner_nodes, edges)
    attr(graph, "admixture_proportions") <- admix_props
    graph
}


