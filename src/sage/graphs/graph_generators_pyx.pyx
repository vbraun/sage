r"""
Common graphs and digraphs generators (Cython)

AUTHORS:

- David Coudert (2012)
"""


################################################################################
#           Copyright (C) 2012 David Coudert <david.coudert@inria.fr>
#
# Distributed  under  the  terms  of  the  GNU  General  Public  License (GPL)
#                         http://www.gnu.org/licenses/
################################################################################

from sage.misc.randstate cimport random

def RandomGNP(n, p, bint directed=False, bint loops=False):
    r"""
    Return a random graph or a digraph on `n` nodes.

    Each edge is inserted independently with probability `p`.

    INPUT:

    - ``n`` -- number of nodes of the digraph

    - ``p`` -- probability of an edge

    - ``directed`` -- boolean (default: ``False``); whether the random graph is
      directed or undirected (default)

    - ``loops`` -- boolean (default: ``False``); whether the random digraph may
      have loops or not. This value is used only when ``directed == True``.

    REFERENCES:

    - [ER1959]_

    - [Gil1959]_

    EXAMPLES::

        sage: from sage.graphs.graph_generators_pyx import RandomGNP
        sage: set_random_seed(0)
        sage: D = RandomGNP(10, .2, directed=True)
        sage: D.num_verts()
        10
        sage: D.edges(labels=False)
        [(0, 2), (0, 5), (1, 5), (1, 7), (4, 1), (4, 2), (4, 9), (5, 0), (5, 2), (5, 3), (5, 7), (6, 5), (7, 1), (8, 2), (8, 6), (9, 4)]

    TESTS::

        sage: abs(mean([RandomGNP(200, .2).density() for i in range(30)]) - .2) < .001
        True
        sage: RandomGNP(150, .2, loops=True)
        Traceback (most recent call last):
        ...
        ValueError: parameter 'loops' can be set to True only when 'directed' is True
    """
    from sage.graphs.graph import Graph, DiGraph

    # according the sage.misc.randstate.pyx documentation, random
    # integers are on 31 bits. We thus set the pivot value to p*2^31
    cdef float RAND_MAX_f = float(1<<31)
    cdef int pp = int(round(float(p * RAND_MAX_f)))

    if directed:
        G = DiGraph(loops=loops)
    else:
        G = Graph()
        if loops:
            raise ValueError("parameter 'loops' can be set to True only when 'directed' is True")
    G.name('Random' + ('Directed' if directed else '') + 'GNP(%s,%s)' % (n, p))

    G.add_vertices(range(n))

    # Standard random GNP generator for Graph and DiGraph
    cdef int i, j
    for i in range(n):
        for j in range((0 if directed else i + 1), n):
            if random() < pp:
                if i != j or loops:
                    G.add_edge(i, j)

    return G
