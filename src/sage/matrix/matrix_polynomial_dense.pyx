"""
Dense matrices over univariate polynomials over fields

This implementation inherits from Matrix_generic_dense, i.e. it is not
optimized for speed only some methods were added.

AUTHOR:

* Kwankyu Lee <ekwankyu@gmail.com>
"""

#*****************************************************************************
#       Copyright (C) 2016 Kwankyu Lee <ekwankyu@gmail.com>
#
#  Distributed under the terms of the GNU General Public License (GPL)
#  as published by the Free Software Foundation; either version 2 of
#  the License, or (at your option) any later version.
#                  http://www.gnu.org/licenses/
#*****************************************************************************

from sage.matrix.matrix_generic_dense cimport Matrix_generic_dense

cdef class Matrix_polynomial_dense(Matrix_generic_dense):
    """
    Dense matrix over a univariate polynomial ring over a field.
    """

    def is_weak_popov(self):
        r"""
        Return ``True`` if the matrix is in weak Popov form.

        OUTPUT:

        A matrix over an ordered ring is in weak Popov form if all
        leading positions are different [MS2003]_. A leading position
        is the position `i` in a row with the highest order (for
        polynomials this is the degree), for multiple entries with
        equal but highest order the maximal `i` is chosen (which is
        the furthest to the right in the matrix).

        .. WARNING::

            This implementation only works for objects implementing a degree
            function. It is designed to work for polynomials.

        EXAMPLES:

        A matrix with the same leading position in two rows is not in weak
        Popov form. ::

            sage: PF = PolynomialRing(GF(2^12,'a'),'x')
            sage: A = matrix(PF,3,[x,x^2,x^3,x^2,x^2,x^2,x^3,x^2,x])
            sage: A.is_weak_popov()
            False

        If a matrix has different leading positions, it is in weak Popov
        form. ::

            sage: B = matrix(PF,3,[1,1,x^3,x^2,1,1,1,x^2,1])
            sage: B.is_weak_popov()
            True

        Weak Popov form is not restricted to square matrices. ::

            sage: PF = PolynomialRing(GF(7),'x')
            sage: D = matrix(PF,2,4,[x^2+1,1,2,x,3*x+2,0,0,0])
            sage: D.is_weak_popov()
            False

        Even a matrix with more rows than cols can still be in weak Popov
        form. ::

            sage: E = matrix(PF,4,2,[4*x^3+x,x^2+5*x+2,0,0,4,x,0,0])
            sage: E.is_weak_popov()
            True

        But a matrix with less cols than non zero rows is never in weak
        Popov form. ::

            sage: F = matrix(PF,3,2,[x^2,x,x^3+2,x,4,5])
            sage: F.is_weak_popov()
            False

        TESTS:

        A matrix to check if really the rightmost value is taken. ::

            sage: F = matrix(PF,2,2,[x^2,x^2,x,5])
            sage: F.is_weak_popov()
            True

        .. SEEALSO::

            - :meth:`weak_popov_form <sage.matrix.matrix2.weak_popov_form>`

        AUTHOR:

        - David Moedinger (2014-07-30)
        """
        t = set()
        for r in range(self.nrows()):
            max = -1
            for c in range(self.ncols()):
                if self[r, c].degree() >= max:
                    max = self[r, c].degree()
                    p = c
            if not max == -1:
                if p in t:
                    return False
                t.add(p)
        return True

    def weak_popov_form(self, transformation=None, ascend=None, old_call=True):
        """
        Return a matrix in weak Popov form which is row space-equivalent to
        the input matrix.

        A matrix is in weak Popov form if the leading positions of
        the non-zero rows are all different. The leading position of a row is
        the right-most position whose entry has maximal degree of the entries in
        that row.

        .. WARNING::

            This function currently does **not** compute the weak Popov form of a
            matrix, but rather a row reduced form (which is a slightly weaker
            requirement). See :meth:`row_reduced_form`.

        INPUT:

        - `transformation` - A boolean (default: `True`). If this is set to
          ``True``, the transformation matrix `U` will be returned as well: this
          is an invertible matrix over `k(x)` such that ``self`` equals `UW`,
          where `W` is the output matrix.

          Warning: the default of `transformation` will soon be set to ``False``,
          see :trac:`16896`. Until then, this function will print a deprecation
          warning as long as `transformation` was not explicitly set to ``True``
          or ``False``.

        - `ascend` - Deprecated and has no effect.

        - `old_call` - For backwards compatibility until the old calling
          convention will be deprecated (default: `True`). If `True`, then
          return `(W,U,d)`, where `U` is as when `transformation = True`, and
          `d` is a list of the degrees of the rows of `W`.
        """
        from sage.misc.superseded import deprecation
        deprecation(16888, "This function currently does *not* compute a weak Popov form, "
        "but rather a row reduced form. This function will soon be fixed (see Ticket #16742).")

        return self.row_reduced_form(transformation=transformation,
                ascend=ascend, old_call=old_call)

    def _weak_popov_form(self, transformation=False):
        """
        Return a matrix in weak Popov form which is row space-equivalent to
        the input matrix, if the input is over `k[x]` or `k(x)`.

        A matrix is in weak Popov form if the (row-wise) leading positions of
        the non-zero rows are all different. The leading position of a row is
        the right-most position whose entry has maximal degree of the entries in
        that row.

        INPUT:

        - ``transformation`` -- (default: `True`). If this is set to
          ``True``, the transformation matrix `U` will be returned as well: this
          is an invertible matrix over `k(x)` such that ``self`` equals `UW`,
          where `W` is the output matrix.

        ALGORITHM::

            This function uses the mulders-storjohann algorithm of [MS].
            It works as follow:
            #. As long as M is not in weak popov form do:
                #. Find two rows with conflicting leading positions.
                #. Do a simple transformation:
                    #. Let x and y be indicators of rows with identical
                       leading position
                    #. Let LP be the Leading Position and LC the Leading
                       Coefficient
                    #. let a = LP(M[x]).degree() - LP(M[y]).degree()
                    #. let d = LC(LP(M[x])) / LC(LP(M[y]))
                    #. substitute M[x] = M[x] - a * x^d * M[y]

        EXAMPLES:

        The value transposition can be used to get a second matrix to check
        unimodular equivalence. ::

            sage: F.<a> = GF(2^4,'a')
            sage: PF.<x> = F[]
            sage: A = matrix(PF,[[1,a*x^17+1],[0,a*x^11+a^2*x^7+1]])
            sage: Ac = copy(A)
            sage: au = A.weak_popov_form(implementation="cython",transposition=True)
            sage: au[1]*Ac == au[0]
            True
            sage: au[1].is_invertible()
            True

        The cython implementation can be used to speed up the computation of
        a weak popov form. ::

            sage: B = matrix(PF,[[x^2+a,x^2+a,x^2+a], [x^3+a*x+1,x+a^2,x^5+a*x^4+a^2*x^3]])
            sage: B.weak_popov_form(implementation="cython")
            [                    x^2 + a                     x^2 + a
                  x^2 + a]
            [x^5 + (a + 1)*x^3 + a*x + 1       x^5 + a*x^3 + x + a^2       a*x^4 +
            (a^2 + a)*x^3]

        Matrices containing only zeros will return the way they are. ::

            sage: Z = matrix(PF,5,3)
            sage: Z.weak_popov_form(implementation="cython")
            [0 0 0]
            [0 0 0]
            [0 0 0]
            [0 0 0]
            [0 0 0]

        Generally matrices in weak popov form will just be returned. ::

            sage: F.<a> = GF(17,'a')
            sage: PF.<x> = F[]
            sage: C = matrix(PF,[[1,7,x],[x^2,x,4],[2,x,11]])
            sage: C.weak_popov_form(implementation="cython")
            [  1   7   x]
            [x^2   x   4]
            [  2   x  11]

        And the transposition will be the identity matrix. ::

            sage: C.weak_popov_form(implementation="cython",transposition=True)
            (
            [  1   7   x]  [1 0 0]
            [x^2   x   4]  [0 1 0]
            [  2   x  11], [0 0 1]
            )


        It is an error to call this function with a matrix not over a polynomial
        ring. ::

            sage: M = matrix([[1,0],[1,1]])
            sage: M.weak_popov_form(implementation="cython")
            Traceback (most recent call last):
            ...
            TypeError: the entries of M must lie in a univariate polynomial ring

        It is also an error to call this function using a matrix containing
        elements of the fraction field. ::

            sage: R.<t> = QQ['t']
            sage: M = matrix([[1/t,1/(t^2),t],[0,0,t]])
            sage: M.weak_popov_form(implementation="cython")
            Traceback (most recent call last):
            ...
            TypeError: the entries of M must lie in a univariate polynomial ring

        This function can be called directly. ::

            sage: from sage.matrix.weak_popov import mulders_storjohann
            sage: PF = PolynomialRing(GF(2,'a'),'x')
            sage: E = matrix(PF,[[x+1,x,x],[x^2,x,x^4+x^3+x^2+x]])
            sage: mulders_storjohann(E)
            [          x + 1               x               x]
            [x^4 + x^3 + x^2         x^4 + x   x^3 + x^2 + x]


        .. SEEALSO::

            :meth:`is_weak_popov <sage.matrix.matrix0.is_weak_popov>`

        REFERENCES::

        .. [MS] T. Mulders, A. Storjohann, "On lattice reduction for polynomial
              matrices," J. Symbolic Comput. 35 (2003), no. 4, 377--401
        """
        mat = self.__copy__()
        R = mat.base_ring()
        m = mat.nrows()
        n = mat.ncols()
        x = R.gen()

        if transformation:
            from sage.matrix.constructor import identity_matrix
            U = identity_matrix(R, m)
        else:
            U = None

        retry = True
        while retry:
            retry = False
            pivot_cols = []
            for i in range(m):
                j = 0
                prev_deg = -1
                col = -1
                for j in range(n):
                    curr_deg = mat[i,j].degree()
                    if curr_deg >= 0 and prev_deg <= curr_deg:
                        prev_deg = curr_deg
                        col = j
                if col < 0: # zero row
                    pivot_cols.append(col)
                    continue
                elif col in pivot_cols:
                    r = pivot_cols.index(col)
                    cr = mat[r,col].leading_coefficient()
                    dr = mat[r,col].degree()
                    ci = mat[i,col].leading_coefficient()
                    di = mat[i,col].degree()
                    if di >= dr:
                        q = R(-ci/cr).shift(di-dr)
                        mat[i] += q * mat[r]
                        if transformation:
                            U.add_multiple_of_row(i, r, q)
                    else:
                        q = R(-cr/ci).shift(dr-di)
                        mat[r] += q * mat[i]
                        if transformation:
                            U.add_multiple_of_row(r, i, q)
                    retry = True
                    break
                else:
                    pivot_cols.append(col)

        if transformation:
            return mat, U
        else:
            return mat

    def row_reduced_form(self, transformation=None, ascend=None, old_call=True):
        r"""
        Return a row reduced form of this matrix.

        A matrix `M` is row reduced if the leading term matrix has the same rank
        as `M`. The leading term matrix of a polynomial matrix `M_0` is the matrix
        over `k` whose `(i,j)`'th entry is the `x^{d_i}` coefficient of `M_0[i,j]`,
        where `d_i` is the greatest degree among polynomials in the `i`'th row of `M_0`.

        INPUT:

        - `transformation` - A boolean (default: ``False``). If this is set to
          ``True``, the transformation matrix `U` will be returned as well: this
          is an invertible matrix over `k(x)` such that ``self`` equals `UW`,
          where `W` is the output matrix.

        - `ascend` - Deprecated and has no effect.

        - `old_call` - For backwards compatibility until the old calling
          convention will be deprecated (default: `True`). If `True`, then
          return `(W,U,d)`, where `U` is as when `transformation = True`, and
          `d` is a list of the degrees of the rows of `W`.

        OUTPUT:

        - `W` - a matrix over the same ring as `self` (i.e. either `k(x)` or
          `k[x]` for a field `k`) giving a row reduced form of ``self``.

        EXAMPLES::

            sage: R.<t> = GF(3)['t']
            sage: K = FractionField(R)
            sage: M = matrix([[(t-1)^2],[(t-1)]])
            sage: M.row_reduced_form(transformation=False, old_call=False)
            [    0]
            [t + 2]

        If ``self`` is an `n \times 1` matrix with at least one non-zero entry,
        `W` has a single non-zero entry and that entry is a scalar multiple of
        the greatest-common-divisor of the entries of ``self``.

        ::

            sage: M1 = matrix([[t*(t-1)*(t+1)],[t*(t-2)*(t+2)],[t]])
            sage: output1 = M1.row_reduced_form(transformation=False, old_call=False)
            sage: output1
            [0]
            [0]
            [t]

        The following is the first half of example 5 in [Hes2002]_ *except* that we
        have transposed ``self``; [Hes2002]_ uses column operations and we use row.

        ::

            sage: R.<t> = QQ['t']
            sage: M = matrix([[t^3 - t,t^2 - 2],[0,t]]).transpose()
            sage: M.row_reduced_form(transformation=False, old_call=False)
            [      t    -t^2]
            [t^2 - 2       t]

        The next example demonstrates what happens when ``self`` is a zero matrix.

        ::

            sage: R.<t> = GF(5)['t']
            sage: M = matrix(R, 2, [0,0,0,0])
            sage: M.row_reduced_form(transformation=False, old_call=False)
            [0 0]
            [0 0]

        In the following example, ``self`` has more rows than columns. Note also
        that the output is row reduced but not in weak Popov form (see
        :meth:`weak_popov_form`).

        ::

            sage: R.<t> = QQ['t']
            sage: M = matrix([[t,t,t],[0,0,t]])
            sage: M.row_reduced_form(transformation=False, old_call=False)
            [t t t]
            [0 0 t]

        The last example shows the usage of the transformation parameter.

        ::

            sage: Fq.<a> = GF(2^3)
            sage: Fx.<x> = Fq[]
            sage: A = matrix(Fx,[[x^2+a,x^4+a],[x^3,a*x^4]])
            sage: W,U = A.row_reduced_form(transformation=True,old_call=False);
            sage: W,U
            (
            [(a^2 + 1)*x^3 + x^2 + a                       a]  [      1 a^2 + 1]
            [                    x^3                   a*x^4], [      0                 1]
            )
            sage: U*W == A
            True
            sage: U.is_invertible()
            True

        NOTES:

         - For consistency with LLL and other algorithms in Sage, we have opted
           for row operations; however, references such as [Hes2002]_ transpose and use
           column operations.

         - There are multiple weak Popov forms of a matrix, so one may want to
           extend this code to produce a Popov form (see section 1.2 of [V]).  The
           latter is canonical, but more work to produce.

        .. SEEALSO::

            :meth:`is_weak_popov <sage.matrix.matrix0.is_weak_popov>`

        REFERENCES:

        - [Hes2002]_
        - [Kal1980]_

        """
        from sage.matrix.matrix_misc import row_reduced_form

        from sage.misc.superseded import deprecation
        if ascend is not None:
            deprecation(16888,
            "row_reduced_form: The `ascend` argument is deprecated "
            "and has no effect (see Ticket #16742).")
        if old_call == True:
            deprecation(16888,
            "row_reduced_form: The old calling convention is deprecated. "
            "In the future, only the matrix in row reduced form will be returned. "
            "Set `old_call = False` for that behaviour now, and to avoid this "
            "message (see Ticket #16742).")

        get_transformation = False
        if transformation is None:
            deprecation(16888,
            "row_reduced_form: The `transformation` argument will soon change to have "
            "default value to `False` from the current default value `True`. For now, "
            "explicitly setting the argument to `True` or `False` will avoid this message.")
            get_transformation = True
        elif old_call == True or transformation == True:
            get_transformation = True

        W_maybe_U = self._row_reduced_form(get_transformation)

        if not old_call:
            return W_maybe_U
        else:
            W, U = W_maybe_U
            row_deg = lambda r: max([e.degree() for e in r])
            d = []
            from sage.rings.all import infinity
            for r in W.rows():
                d.append(row_deg(r))
                if d[-1] < 0:
                    d[-1] = -infinity
            return (W,U,d)

    def _row_reduced_form(self, transformation=False):
        """
        Return a row reduced form of this matrix.

        INPUT:

        - ``transformation`` -- (default: ``False``). If this is ``True``,
           the transformation matrix is output.

        OUTPUT:

        If ``transformation`` is ``True``, this function will output matrices ``W`` and ``N`` such that

        1. ``W`` -- a row reduced form of this matrix ``M``.
        2. ``N`` -- a unimodular matrix satisfying ``N * W = M``.

        If `transformation` is `False`, the output is just ``W``.

        EXAMPLES::

            sage: Fq.<a> = GF(2^3)
            sage: Fx.<x> = Fq[]
            sage: A = matrix(Fx,[[x^2+a,x^4+a],[x^3,a*x^4]])
            sage: A._row_reduced_form(transformation=True)
            (
            [(a^2 + 1)*x^3 + x^2 + a                       a]  [      1 a^2 + 1]
            [                    x^3                   a*x^4], [      0                 1]
            )
        """

        # determine whether M has polynomial or rational function coefficients
        R = self.base_ring()
        t = R.gen()

        from sage.matrix.constructor import matrix

        num = self
        r = [list(v) for v in num.rows()]

        if transformation:
            N = matrix(num.nrows(), num.nrows(), R(1)).rows()

        rank = 0
        num_zero = 0
        if num.is_zero():
            num_zero = len(r)
        while rank != len(r) - num_zero:
            # construct matrix of leading coefficients
            v = []
            for w in map(list, r):
                # calculate degree of row (= max of degree of entries)
                d = max([e.numerator().degree() for e in w])

                # extract leading coefficients from current row
                x = []
                for y in w:
                    if y.degree() >= d and d >= 0:   x.append(y.coefficients(sparse=False)[d])
                    else:                            x.append(0)
                v.append(x)
            l = matrix(v)

            # count number of zero rows in leading coefficient matrix
            # because they do *not* contribute interesting relations
            num_zero = 0
            for v in l.rows():
                is_zero = 1
                for w in v:
                    if w != 0:
                        is_zero = 0
                if is_zero == 1:
                    num_zero += 1

            # find non-trivial relations among the columns of the
            # leading coefficient matrix
            kern = l.kernel().basis()
            rank = num.nrows() - len(kern)

            # do a row operation if there's a non-trivial relation
            if not rank == len(r) - num_zero:
                for rel in kern:
                    # find the row of num involved in the relation and of
                    # maximal degree
                    indices = []
                    degrees = []
                    for i in range(len(rel)):
                        if rel[i] != 0:
                            indices.append(i)
                            degrees.append(max([e.degree() for e in r[i]]))

                    # find maximum degree among rows involved in relation
                    max_deg = max(degrees)

                    # check if relation involves non-zero rows
                    if max_deg != -1:
                        i = degrees.index(max_deg)
                        rel /= rel[indices[i]]

                        for j in range(len(indices)):
                            if j != i:
                                # do the row operation
                                v = []
                                for k in range(len(r[indices[i]])):
                                    v.append(r[indices[i]][k] + rel[indices[j]] * t**(max_deg-degrees[j]) * r[indices[j]][k])
                                r[indices[i]] = v

                                if transformation:
                                    # If the user asked for it, record the row operation
                                    v = []
                                    for k in range(len(N[indices[i]])):
                                        v.append(N[indices[i]][k] + rel[indices[j]] * t**(max_deg-degrees[j]) * N[indices[j]][k])
                                    N[indices[i]] = v

                        # remaining relations (if any) are no longer valid,
                        # so continue onto next step of algorithm
                        break

        A = matrix(R, r)
        if transformation:
            return (A, matrix(N))
        else:
            return A
