# Factory method for regular sparse matrices

require_relative "AbstractSparseMatrixFactory"
require_relative "RegSparseDataStructure"

class RegSparseMatrixFactory < AbstractSparseMatrixFactory

  # create a regular sparse matrix with the given arguments
  def create(*args)
    # create a new matrix based on the input matrix
    if args.size == 1
      if args[0].is_a? Matrix
        dataStruct = RegSparseDataStructure.new(args[0])
        mat = SparseMatrix.new(dataStruct)
        return mat
      end
      # create a blank matrix
    elsif args.size == 2
      print args
      dataStruct = RegSparseDataStructure.new(*args)
      mat = SparseMatrix.new(dataStruct)
      return mat
    end

    raise "Invalid arguments"
  end

end