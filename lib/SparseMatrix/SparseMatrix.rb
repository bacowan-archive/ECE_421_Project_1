# Base class for the sparse matrix. This class is mostly
# used as a framework to delegate functionality to its inner
# representations, that is, AbstractDataStructure.


require_relative "AbstractDataStructure"
require_relative "RegSparseMatrixFactory"
require "matrix"

class SparseMatrix

  def SparseMatrix.DEBUG_FLAG
    #"DEBUG_FLAG"
    true
  end

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

  def det
    return @delegate.det
  end

  def inv
    newDelegate = @delegate.clone
    return newDelegate.inv
  end

  def rank
    return @delegate.rank
  end

  def rotate(val)
    newDelegate = @delegate.clone
    return newDelegate.rotate(val)
  end

  def row(index)
    return @delegate.row(index)
  end

  def rowSwitch(index1, index2, dim)
    newDelegate = @delegate.clone
    return newDelegate.rowSwitch(index1,index2,dim)
  end

  def size
    return @delegate.size
  end

  # return the transpose of this matrix
  def transpose(*args)
    unless args.length == 0 or args.length == 1
      raise 'wrong number of args'
    end
    debug = false
    if args.length > 0 and args[0] == SparseMatrix.DEBUG_FLAG
      debug = true
    end

    # pre-conditions and invariants
    if debug
      _invariants
    end

    newDelegate = @delegate.clone
     newDelegate.transpose

    newMatrix = SparseMatrix.new(newDelegate)

    # post-conditions and invariants
    if debug
      _invariants
      assert_equal(self.row_size,newMatrix.column_size,"post-condition")
      assert_equal(self.column_size,newMatrix.row_size,"post-condition")
      (0..self.row_size-1).each { |i|
        (0..self.column_size-1).each { |j|
          assert_equal(self[i,j],newMatrix[j,i],"post-condition")
        }
      }
    end

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
  def put(*args)
    unless args.length == 2 or args.length == 3
      raise 'wrong number of args'
    end

    index = args[0]
    val = args[1]

    debug = false
    if args.length == 3 and args[2] == SparseMatrix.DEBUG_FLAG
      debug = true
    end

    if debug
      # preconditions and invariants
      _invariants
      assert(_inbounds(index,self),"pre-condition")
      assert((val.is_a? Numeric), "pre-condition")
      # keep track for post-conditions
      oldVal = self[index]
      oldRepItemCount = self.internalRepItemCount
    end

    @delegate.put(index,val)

    # post conditions and invariants
    if debug
      _invariants
      assert_equal( self[index], val, "post-condition" )
      assert(self.include?(val), "post-condition")
      # slightly different behavior for setting zero and non-zero values
      if val == 0 and oldVal != 0
        assert_equal(self.internalRepItemCount,oldRepItemCount-1,"post-condition")
      elsif (val != 0 and oldVal != 0) or (val == 0 and oldVal == 0)
        assert_equal(self.internalRepItemCount,oldRepItemCount,"post-condition")
      elsif val != 0 and oldVal == 0
        assert_equal(self.internalRepItemCount,oldRepItemCount+1,"post-condition")
      end
    end

  end

  # go through all elements in the array, including zeros.
  # go row by row, then column by column
  def each(&block)
    (0..@delegate.getRowSize-1).each { |row|
      (0..@delegate.getColSize-1).each { |col|
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

  def rowOper(index1,index2,oper)
    dup = @delegate.clone
    return dup.rowOper(index1,index2,oper)
  end

  # get the column size
  def column_size
    @delegate.getColSize
  end

  # Create a submatrix of this, removing rows and cols
  def subMatrix(*args)
    unless args.length == 2 or args.length == 3
      raise 'wrong number of args'
    end

    rows = args[0]
    cols = args[1]

    debug = false
    if args.length == 3 and args[2] == SparseMatrix.DEBUG_FLAG
      debug = true
    end

    if debug
    # preconditions and invariants
      _invariants
      rows.each { |i|
        assert(i >= 0, "pre-condition")
        assert(i < row_size, "pre-condition")
      }
      cols.each { |i|
        assert(i >= 0, "pre-condition")
        assert(i < column_size, "pre-condition")
      }
    end

    newDelegate = @delegate.clone
    newDelegate.subMatrix(rows,cols)
    newMatrix = SparseMatrix.new(newDelegate)


    if debug
      # post-conditions and invariants
      _invariants
      assert_equal(newMatrix.column_size,column_size-cols.uniq.length,"post-condition")
      assert_equal(newMatrix.row_size,row_size-rows.uniq.length,"post-condition")
    end


    return newMatrix
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
    mat = Matrix.zero(row_size,column_size)
    self.each_with_index { |index,val|
      mat[index[0],index[1]] = val
    }
    return "Sparse" + mat.to_s
  end

  # add this matrix to another
  def +(*args)
    unless args.length == 1 or args.length == 2
      raise 'wrong number of args'
    end

    other = args[0]

    debug = false
    if args.length == 2 and args[1] == SparseMatrix.DEBUG_FLAG
      debug = true
    end

    # invariants and pre-conditions
    if debug
      _invariants
      if other.respond_to? :getDelegate
        assert_equal(self.row_size,other.row_size,"pre-condition")
        assert_equal(self.column_size,other.column_size,"pre-condition")
      elsif other.is_a? Numeric
        # no pre-conditions
      else
        assert(false,"pre-condition")
      end
    end


    if other.respond_to? :getDelegate
      newDelegate = @delegate + other.getDelegate
    elsif other.is_a? Numeric
      newDelegate = @delegate + other
    else
      raise "not a sparse matrix object or scalar"
    end
    newMatrix = SparseMatrix.new(newDelegate)

    if debug
      # post-conditions and invariants
      _invariants
      if other.respond_to? :getDelegate
        assert_equal(newMatrix.row_size,self.row_size,"post-condition")
        assert_equal(newMatrix.column_size,self.column_size,"post-condition")
        assert_equal(newMatrix.toBaseMatrix,other.toBaseMatrix+self.toBaseMatrix,"post-condition")
      elsif other.is_a? Numeric
        assert_equal(newMatrix.row_size,self.row_size,"post-condition")
        assert_equal(newMatrix.column_size,self.column_size,"post-condition")
        assert_equal(newMatrix.toBaseMatrix,Matrix.build(self.row_size,self.column_size){|x,y| self[x,y]+other},"post-condition")
      end
    end

    return newMatrix
  end

  # subtract another matrix from this one
  def -(*args)
    unless args.length == 1 or args.length == 2
      raise 'wrong number of args'
    end

    other = args[0]

    debug = false
    if args.length == 2 and args[1] == SparseMatrix.DEBUG_FLAG
      debug = true
    end

    # invariants and pre-conditions
    if debug
      _invariants
      if other.respond_to? :getDelegate
        assert_equal(self.row_size,other.row_size,"pre-condition")
        assert_equal(self.column_size,other.column_size,"pre-condition")
      elsif other.is_a? Numeric
        # no pre-conditions
      else
        assert(false,"pre-condition")
      end
    end


    if other.respond_to? :getDelegate
      newDelegate = @delegate - other.getDelegate
    elsif other.is_a? Numeric
      newDelegate = @delegate - other
    else
      raise "not a sparse matrix object or scalar"
    end
    newMatrix = SparseMatrix.new(newDelegate)

    if debug
      # post-conditions and invariants
      _invariants
      if other.respond_to? :getDelegate
        assert_equal(newMatrix.row_size,self.row_size,"post-condition")
        assert_equal(newMatrix.column_size,self.column_size,"post-condition")
        assert_equal(newMatrix.toBaseMatrix,self.toBaseMatrix-other.toBaseMatrix,"post-condition")
      elsif other.is_a? Numeric
        assert_equal(newMatrix.row_size,self.row_size,"post-condition")
        assert_equal(newMatrix.column_size,self.column_size,"post-condition")
        assert_equal(newMatrix.toBaseMatrix,Matrix.build(self.row_size,self.column_size){|x,y| self[x,y]-other},"post-condition")
      end
    end



    return newMatrix
  end

  # matrix multiplication on another matrix or a scalar
  def *(*args)
    unless args.length == 1 or args.length == 2
      raise 'wrong number of args'
    end

    other = args[0]

    debug = false
    if args.length == 2 and args[1] == SparseMatrix.DEBUG_FLAG
      debug = true
    end

    # invariants and pre-conditions
    if debug
      _invariants
      if other.respond_to? :getDelegate
        assert_equal(other.row_size,self.column_size,"pre-condition")
      elsif other.is_a? Numeric
        # no preconditions
      else
        raise "not a sparse matrix object or scalar"
      end
    end



    if other.respond_to? :getDelegate
      result = SparseMatrix.create(self.row_size,other.column_size)
      self.each_with_index {|index,val|
        (0..other.column_size-1).each {|i|
          result.put([index[0],i], result[index[0],i] + val*other[index[1],i])
        }
      }
    elsif other.is_a? Numeric
      newDelegate = @delegate * other
      result = SparseMatrix.new(newDelegate)
    end


    if debug
      # post-conditions and invariants
      _invariants
      if other.respond_to? :getDelegate
        assert_equal(result.row_size,self.row_size,"post-condition")
        assert_equal(result.column_size,other.column_size,"post-condition")
        assert_equal(result.toBaseMatrix,self.toBaseMatrix*other.toBaseMatrix,"post-condition")
      elsif other.is_a? Numeric
        assert_equal(result.row_size,self.row_size,"post-condition")
        assert_equal(result.column_size,self.column_size,"post-condition")
        assert_equal(result.toBaseMatrix,self.toBaseMatrix*other,"post-conditions")
      end
    end


    return result

  end

  # do the elementwise multiplication of the matrix to another
  def elementMult(*args)
    unless args.length == 1 or args.length == 2
      raise 'wrong number of args'
    end

    other = args[0]

    debug = false
    if args.length == 2 and args[1] == SparseMatrix.DEBUG_FLAG
      debug = true
    end

    # pre-conditions and invariants
    if debug
      assert((other.respond_to? :[]), "pre-condition")
      _invariants
      assert_equal(self.row_size,other.row_size, "pre-condition")
      assert_equal(self.column_size,other.row_size, "pre-condition")
    end


    result = self.clone
    self.each_with_index {|index,val|
      result.put(index, val * other[index] )
    }

    # post-conditions and invariants
    if debug
      _invariants
      assert_equal(result.toBaseMatrix,Matrix.build(self.row_size,self.column_size) {|x,y| self[x,y] * other[x,y]}, "post-condition")
    end


    return result
  end

  def flipHorizontal(*args)
    unless args.length == 0 or args.length == 1
      raise 'wrong number of args'
    end

    debug = false
    if args.length == 1 and args[0] == SparseMatrix.DEBUG_FLAG
      debug = true
    end

    # pre-conditions and invariants
    if debug
      _invariants
    end


    newDelegate = self.getDelegate.clone
    newDelegate.flipHorizontal
    result = SparseMatrix.new(newDelegate)

    # post-conditions and invariants
    if debug
      _invariants
      assert_equal(result.internalRepItemCount,self.internalRepItemCount,"post-condition")
      result.each_with_index { |index,val|
        row = index[0]
        col = index[1]
        assert_equal(val,self[row,self.column_size-1-col],"post-condition")
      }
    end


    return result
  end

  def flipVertical(*args)
    unless args.length == 0 or args.length == 1
      raise 'wrong number of args'
    end

    debug = false
    if args.length == 1 and args[0] == SparseMatrix.DEBUG_FLAG
      debug = true
    end

    if debug
      # pre-conditions and invariants
      _invariants
    end



    newDelegate = self.getDelegate.clone
    newDelegate.flipVertical
    result = SparseMatrix.new(newDelegate)

    if debug
      # post-conditions and invariants
      _invariants
      assert_equal(result.internalRepItemCount,self.internalRepItemCount,"post-condition")
      result.each_with_index { |index,val|
        row = index[0]
        col = index[1]
        assert_equal(val,self[self.row_size-1-row,col],"post-condition")
      }
    end


    return result
  end

  # return the delegate of this matrix
  def getDelegate
    return @delegate
  end

  # return the ruby Matrix representation of the array
  def toBaseMatrix
    return @delegate.toBaseMatrix
  end

  # return true if and only if this matrix contains equal elements to other
  def ==(other)
    return false unless other.is_a? SparseMatrix
    return false unless self.internalRepItemCount == other.internalRepItemCount
    self.each_with_index {|index,val|
      return false unless other[index] == val
    }
  end

  # assert that the condition is true. If not, throw an error
  def assert(condition,conditionType)
    raise "#{conditionType} not met. " unless condition
  end

  # assert that two values are equal
  def assert_equal(val1,val2,conditionType)
    begin
      assert(val1==val2,conditionType)
    rescue Exception => e
      raise e.message + "Expected \n#{val1}, got\n#{val2}"
    end

  end

  def assert_not_equal(val1,val2,conditionType)
    begin
      assert(val1!=val2,conditionType)
    rescue Exception => e
      raise e.message + "Expected anything but\n#{val1}, got\n#{val2}"
    end
  end

  # check if the given index is in the matrix bounds
  # +index+:: the index in the matrix, in the form [row,col]
  # +matrix+:: the matrix to test the bounds of
  # true is returned if the index is inbound in the matrix. false otherwise
  def _inbounds(index,matrix)
    if index[0] > matrix.row_size or index[0] < 0 or index[1] > matrix.column_size or index[1] < 0
      return false
    end
    return true
  end

  # test the invariants
  def _invariants
    prng = Random.new(SEED)
    # the sparse matrix internal representation should never have
    # more items than zeros in the matrix it represents
    representedMatrix = self.toBaseMatrix
    nonzeros = 0
    representedMatrix.each { |item |
      if item != 0
        nonzeros += 1
      end
    }
    assert_equal(internalRepItemCount, nonzeros,'invariant')

    # there should never be any zero values in the internal matrix
    zeros = 0
    each_with_index { |item, index| zeros += 1 if item == 0 }
    assert_equal(zeros,0,'invariant')

    # make sure the sparse matrix is in the bounds of the original
    maxRow = nil
    self.each_with_index { |index, item|
      unless maxRow.nil?
        maxRow = [maxRow, index[0]].max
      else
        maxRow = index[0]
      end
    }
    assert(maxRow <= representedMatrix.row_size,'invariant')

    minRow = nil
    each_with_index { |item, index|
      unless minRow.nil?
        minRow = [minRow, index[0]].min
      else
        minRow = index[0]
      end
    }
    assert(minRow >= 0,'invariant')

    maxCol = nil
    each_with_index { |item, index|
      unless maxCol.nil?
        maxCol = [maxCol, index[1]].max
      else
        maxCol = index[1]
      end
    }
    assert(maxCol <= representedMatrix.column_size,'invariant')

    minCol = nil
    each_with_index { |item, index|
      unless minCol.nil?
        minCol = [minCol, index[1]].min
      else
        minCol = index[1]
      end
    }
    assert(minCol >= 0,'invariant')

    # Insure that our matrix starts at 0,0 (as opposed to 1,1, for example)
    assert_equal(self[0,0],representedMatrix[0,0],'invariant')

    # The transpose of a transpose is itself
    assert_equal(transpose.transpose,self,'invariant')

    # a matrix plus a scalar, minus the same scalar is itself
    assert_equal(self+5-5,self,'invariant')

    # a matrix added to a matrix, then subtracted by the same matrix is itself
    # (and vice versa)
    diffMatrixOriginal = Matrix.build(self.row_size, self.column_size) { |row,col| prng.rand(10) }
    diffMatrix = SparseMatrix.create(diffMatrixOriginal)
    assert_equal(self + diffMatrix -diffMatrix ,self,'invariant')
    assert_equal(self - diffMatrix + diffMatrix ,self,'invariant')

    # The inverse of the determinant is the same as the determinant of the inverse
    #assert_equal(sparseMatrix.inverse.determinant,sparseMatrix.determinant.inverse)

    # if you switch two rows in a matrix back and forth, you will end with the same matrix
    #assert_equal(sparseMatrix.rowSwitch(2,3,0).rowSwitch(2,3,0),sparseMatrix)

    # if you mirror the matrix twice (on either axis), it should be the same as the original
    assert_equal(self.flipHorizontal.flipHorizontal,self,'invariant')
    assert_equal(self.flipVertical.flipVertical,self,'invariant')

    # rotations that total to 360 degrees will be the same as the original matrix
    #assert_equal(sparseMatrix.rotate(0).rotate(0).rotate(0).rotate(0),sparseMatrix)
    #assert_equal(sparseMatrix.rotate(1).rotate(1),sparseMatrix)
    #assert_equal(sparseMatrix.rotate(2).rotate(0),sparseMatrix)

    # the inverse of the inverse of a matrix is itself
    # (this is only true for invertable matrices)
    #begin
    #  assert_equal(sparseMatrix.inverse.inverse,sparseMatrix)
    #rescue NotInvertibleError
    #else
    #  #assert(false)
    #end

  end

end