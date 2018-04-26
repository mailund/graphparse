
#' @import matchbox
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
    edges <- NIL
    admixtures <- NIL

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
        edges <<- CONS(edge, edges)
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
        admixtures <<- CONS(admixture, admixtures)
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

#' @import matchbox
#' @import pmatch
qp_get_edges <- function(graph_info) {
    no_edges <- llength(graph_info$edges)
    no_admixtures <- llength(graph_info$admixtures)

    n <- no_edges + 2 * no_admixtures
    tbl <- character(length = n * 3)
    dim(tbl) <- c(n, 3)

    idx <- 1 ; e <- graph_info$edges
    while(!is_llist_empty(e)) {
        tbl[idx,] <- e$car
        e <- e$cdr
        idx <- idx + 1
    }

    a <- graph_info$admixtures
    while(!is_llist_empty(a)) {
        bind[child,parent1,parent2,.] <- a$car

        prop <- paste0(child, "_", parent1)
        other_prop <- paste0("(1 - ", prop, ")")

        tbl[idx,] <- c(child, parent1, prop)
        idx <- idx + 1
        tbl[idx,] <- c(child, parent2, other_prop)
        idx <- idx + 1

        a <- a$cdr
    }

    tbl
}

qp_get_nodes <- function(edges) {
    inner_nodes <- edges[,2] %>% unique
    leaves <- setdiff(edges[,1], inner_nodes)
    list(inner_nodes = inner_nodes, leaves = leaves)
}

#' Import a qpGraph file into an admixturegraph object
#'
#' @param text Text containing the graph description.
#' @return An admixturegraph object
#' @export
read_qpgraph <- function(text) {
    graph_info <- qp_parse_graph(text)
    edges <- qp_get_edges(graph_info)
    nodes <- qp_get_nodes(edges)
    admixturegraph::agraph(nodes$leaves, nodes$inner_nodes, edges)
}

