
test_graph <- readr::read_file("data-raw/Basic_OngeEA_wArch.dot")
g <- graphparse::read_dot(test_graph)
plot(g)
