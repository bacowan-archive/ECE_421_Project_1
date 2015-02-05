# Base class for the sparse matrix. This class is mostly
# used as a framework to delegate functionality to its inner
# representations, that is, AbstractDataStructure.


require_relative "AbstractDataStructure"
require_relative "RegSparseMatrixFactory"
require "matrix"

class SparseMatrix

  # static factory method for creating a sparse matrix
  # Create a sparse matrix representation of the input matrix
  # +args+:: matrix to create in sparse form
  # return a SparseMatrix
  def self.create(*args)
    # TODO: Note that if we include regular matrices, they have to be children classes of our Sparse Matrix Class
    # if it shouldn't be a sparse matrix
    #   return regular matrix
    # else

    # create a matrix from the given matrix
    if args.size == 1
      if args[0].is_a? Matrix
        fac = RegSparseMatrixFactory.new()
        return fac.create(args[0])
      end
    elsif args.size == 2
      fac = RegSparseMatrixFactory.new()
      return fac.create(*args)
    end

    raise "Invalid arguments"

  end

  # Constructor. Takes a delegate internal structure for
  # assigning its methods to
  # +delegate+:: AbstractDataStructure to assign delegation to
  def initialize(delegate)
    raise "Not a proper delegate" unless delegate.is_a? AbstractDataStructure
    @delegate = delegate
  end

  # return the transpose of this matrix
  def transpose
    newDelegate = @delegate.clone

    newDelegate.transpose

    newMatrix = SparseMatrix.new(newDelegate)
    return newMatrix
  end

  # override the clone operation for a deep clone
  def clone
    newDelegate = @delegate.clone
    return SparseMatrix.new(newDelegate)
  end

  # Insert a value into the matrix
  # +index+:: the index, in form [x,y] to put the value
  # +val+:: the value to insert
  def put(index,val)
    @delegate.put(index,val)
  end

  # go through all elements in the array, including zeros.
  # go row by row, then column by column
  def each(&block)
    (0..@delegate.getRowSize).each { |row|
      (0..@delegate.getColSize).each { |col|
        yield(self[row,col])
      }
    }
  end

  # go through only non-zero elements in the array, in no
  # particular order
  def each_with_index(&block)
    @delegate.each_with_index(&block)
  end

  # get the index from the delegate
  # the input can either be an array of index vals, or each values can be their own input param
  def [](*index)
    if index[0].kind_of?(Array)
      index = index[0]
    end
    return @delegate[index]
  end

  # method for debugging. return the number of elements in the internal representation of the matrix
  def internalRepItemCount
    return @delegate.rowCount
  end

  # get the row size
  def row_size
    @delegate.getRowSize
  end

  # get the column size
  def column_size
    @delegate.getColSize
  end

  # test if a value exists in the matrix
  def include?(val)
    self.each {|item|
      if item.equal?(val)
        return true
      end
    }
    return false
  end

  # string representation of the matrix
  # TODO: simply return a representation of the matrix being represented
  def to_s
    str = []
    self.each { |val|
      str << val
    }
    return str.to_s
  end

  # add this matrix to another
  def +(other)
    raise "not a sparse matrix object" unless other.is_a? SparseMatrix
    newDelegate = @delegate + other.getDelegate
    newMatrix = SparseMatrix.new(newDelegate)
    return newMatrix
  end

  # return the delegate of this matrix
  def getDelegate
    return @delegate
  end

  # return the ruby Matrix representation of the array
  def toBaseMatrix
    return @delegate.toBaseMatrix
  end

end