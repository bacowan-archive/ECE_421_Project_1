# Factory class for creating sparse matrices. The initial implementation
# simply decides whether or not to make a sparse matrix, or a regular
# matrix, and returns the appropriate implementation


class AbstractSparseMatrixFactory

  # Create a sparse matrix representation of the input matrix
  # +matrix+:: matrix to create in sparse form
  # return a SparseMatrix
  def create(*args)
    raise NotImplementedError
  end

end