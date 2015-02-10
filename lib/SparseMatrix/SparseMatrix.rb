# Base class for the sparse matrix. This class is mostly
# used as a framework to delegate functionality to its inner
# representations, that is, AbstractDataStructure.


require_relative "AbstractDataStructure"
require_relative "RegSparseMatrixFactory"
require "matrix"

class SparseMatrix

  def SparseMatrix.DEBUG_FLAG
    "DEBUG_FLAG"
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

  def det(*args)
    unless args.length == 0 or args.length == 1
      raise 'wrong number of args'
    end
    debug = false
    if args.length == 1 and args[0] == SparseMatrix.DEBUG_FLAG
      debug = true
    end

    raise "Matrix Not Square" unless row_size == column_size
    # pre-conditions and invariants
    if debug
      _invariants
    end

    det = @delegate.det

    if debug
      _invariants
      assertEqual(det,self.toBaseMatrix.determinant)
    end

    return det
  end

  def inv(*args)
    unless args.length == 0 or args.length == 1
      raise 'wrong number of args'
    end
    debug = false
    if args.length == 1 and args[0] == SparseMatrix.DEBUG_FLAG
      debug = true
    end

    # pre-conditions and invariants
    raise NotInvertibleError unless row_size == column_size
    raise NotInvertibleError unless self.det != 0
    if debug
      oldDelegate = @delegate.clone
      _invariants
    end

    begin
      newDelegate = @delegate.clone.inv
    rescue
      raise NotInvertibleError
    end


    if debug
      identity = Matrix.I(row_size)
      raise "Inversion False" unless oldDelegate * newDelegate == identity
      assert_equal(newMatrix.column_size, self.column_size, "returning a matrix of the wrong dimensions")
      assert_equal(newMatrix.row_size, self.row_size, "returning a matrix of the wrong dimensions")
      _invariants
    end

    return newDelegate
  end

  def rank(*args)
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

    rank = @delegate.rank

    # post-conditions and invariants
    if debug
      _invariants
    end

    return rank
  end

  def rotate(*args)
    unless args.length == 1 or args.length == 2
      raise 'wrong number of args'
    end

    val = args[0]

    debug = false
    if args.length == 2 and args[0] == SparseMatrix.DEBUG_FLAG
      debug = true
    end

    # pre-conditions and invariants
    if debug
      _invariants
      assert((val == 0 or val == 1 or val == 2), 'val not valid')
    end

    newDelegate = @delegate.clone
    rot = newDelegate.rotate(val)
    newMat = SparseMatrix.new(rot)

    # post-conditions and invariants
    if debug
      _invariants
      assert_equal(self.column_size,rot.row_size,"rotate returning matrix of wrong size")
      assert_equal(self.row_size,rot.column_size,"rotate returning matrix of wrong size")
      if val == 0
        assert_equal(rot[row_size-1,0],self[0,0],"not properly rotated")
      elsif val == 1
        assert_equal(rot[row_size-1,0],self[0,column_size-1],"not properly rotated")
      else
        assert_equal(rot[row_size-1,0],self[row_size-1,column_size-1],"not properly rotated")
      end
    end

    return newMat
  end

  def col(index)
    col = @delegate.col(index)
    return col
  end

  def row(index)
    row = @delegate.row(index)
    return row
  end

  # switch two rows or columns, depending on the dim, where dim is 0 or 1 (rows or columns, respectively)
  def rowSwitch(*args)
    unless args.length == 3 or args.length == 4
      raise 'wrong number of args'
    end

    index1 = args[0]
    index2 = args[1]
    dim = args[2]

    debug = false
    if args.length == 4 and args[3] == SparseMatrix.DEBUG_FLAG
      debug = true
    end

    # pre-conditions and invariants
    if debug
      _invariants
      assert((dim == 0 or dim == 1),"wrong number of dimensions")
      if dim == 0
        _inbounds(index1,0)
        _inbounds(index2,0)
        oldRow1 = row(index1)
        oldRow2 = row(index2)
      else
        _inbounds(0,index1)
        _inbounds(0,index2)
        oldRow1 = col(index1)
        oldRow2 = col(index2)
      end
    end

    newDelegate = @delegate.clone
    switch = newDelegate.rowSwitch(index1,index2,dim)
    newMat = SparseMatrix.new(switch)

    # post-conditions and invariants
    if debug
      _invariants
      if dim == 0
        assert_equal(oldRow1, switch.row(index2),"rows not switched")
        assert_equal(oldRow2, switch.row(index1),"rows not switched")
      else
        assert_equal(oldRow1, switch.col(index2),"columns not switched")
        assert_equal(oldRow2, switch.col(index1),"columns not switched")
      end
    end

    return newMat
  end

  def size(*args)
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

    sz = @delegate.size

    # post-conditions and invariants
    if debug
      _invariants
    end

    return sz
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
      assert_equal(self.row_size,newMatrix.column_size,"post-condition the number of columns in the output is not equal to the number of rows in the input")
      assert_equal(self.column_size,newMatrix.row_size,"post-condition: the number of rows in the output is not equal to the number of columns in the input")
      (0..self.row_size-1).each { |i|
        (0..self.column_size-1).each { |j|
          assert_equal(self[i,j],newMatrix[j,i],"post-condition: the matrix transpose was not correctly preformed")
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
      assert(_inbounds(index,self),"pre-condition: the index given is out of bounds")
      assert((val.is_a? Numeric), "pre-condition: the input value must be numeric")
      # keep track for post-conditions
      oldVal = self[index]
      oldRepItemCount = self.internalRepItemCount
    end

    @delegate.put(index,val)

    # post conditions and invariants
    if debug
      _invariants
      assert(self.include?(val), "post-condition: the item was not put into the matrix")
      assert_equal( self[index], val, "post-condition: the item was not put into the matrix in the proper position" )
      # slightly different behavior for setting zero and non-zero values
      if val == 0 and oldVal != 0
        assert_equal(self.internalRepItemCount,oldRepItemCount-1,"post-condition: put gives an invalid result")
      elsif (val != 0 and oldVal != 0) or (val == 0 and oldVal == 0)
        assert_equal(self.internalRepItemCount,oldRepItemCount,"post-condition: put gives an invalid result")
      elsif val != 0 and oldVal == 0
        assert_equal(self.internalRepItemCount,oldRepItemCount+1,"post-condition: put gives an invalid result")
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
    assert(_inbounds([index1,0],self),"rowOper has inout of bounds items")
    assert(_inbounds([index2,0],self),"rowOper has inout of bounds items")
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
        assert(i >= 0, "pre-condition: one of the given rows is out of bounds")
        assert(i < row_size, "pre-condition: one of the given rows is out of bounds")
      }
      cols.each { |i|
        assert(i >= 0, "pre-condition: one of the given columns is out of bounds")
        assert(i < column_size, "pre-condition: one of the given columns is out of bounds")
      }
    end

    newDelegate = @delegate.clone
    newDelegate.subMatrix(rows,cols)
    newMatrix = SparseMatrix.new(newDelegate)


    if debug
      # post-conditions and invariants
      _invariants
      assert_equal(newMatrix.column_size,column_size-cols.uniq.length,"post-condition: submatrix column count is different from expected")
      assert_equal(newMatrix.row_size,row_size-rows.uniq.length,"post-condition: submatrix row count is different from expected")
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
  def to_s
    mat = Matrix.zero(row_size,column_size).to_a
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
        assert_equal(self.row_size,other.row_size,"pre-condition: the two matrices being added together should have the same number of columns")
        assert_equal(self.column_size,other.column_size,"pre-condition: the two matrices being added together should have the same number of columns")
      elsif other.is_a? Numeric
        # no pre-conditions
      else
        assert(false,"pre-condition: wrong input type for addition")
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
        assert_equal(newMatrix.row_size,self.row_size,"post-condition: the result of scalar addition has a different number of rows than the original")
        assert_equal(newMatrix.column_size,self.column_size,"post-condition: the result of scalar addition has a different number of columns than the original")
        assert_equal(newMatrix.toBaseMatrix,other.toBaseMatrix+self.toBaseMatrix,"post-condition: wrong result from scalar addition")
      elsif other.is_a? Numeric
        assert_equal(newMatrix.row_size,self.row_size,"post-condition: the result of matrix addition has a different number of rows than the original")
        assert_equal(newMatrix.column_size,self.column_size,"post-condition: the result of matrix addition has a different number of columns than the original")
        assert_equal(newMatrix.toBaseMatrix,Matrix.build(self.row_size,self.column_size){|x,y| self[x,y]+other},"post-condition: wrong result from matrix addition")
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
        assert_equal(self.row_size,other.row_size,"pre-conditions: the two matrices being subtracted must have the same number of rows")
        assert_equal(self.column_size,other.column_size,"pre-condition: the two matrices being subtracted must have the same number of rows")
      elsif other.is_a? Numeric
        # no pre-conditions
      else
        assert(false,"pre-condition: invalid input type")
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
        assert_equal(newMatrix.row_size,self.row_size,"post-condition: the result of matrix subtraction has a different number of rows than the original")
        assert_equal(newMatrix.column_size,self.column_size,"post-condition: the result of scalar subtraction has a different number of columns than the original")
        assert_equal(newMatrix.toBaseMatrix,self.toBaseMatrix-other.toBaseMatrix,"post-condition: wrong result from scalar subtraction")
      elsif other.is_a? Numeric
        assert_equal(newMatrix.row_size,self.row_size,"post-condition: the result of matrix subtraction has a different number of rows than the original")
        assert_equal(newMatrix.column_size,self.column_size,"post-condition: the result of matrix subtraction has a different number of columns than the original")
        assert_equal(newMatrix.toBaseMatrix,Matrix.build(self.row_size,self.column_size){|x,y| self[x,y]-other},"post-condition: wrong result from matrix subtraction")
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
        assert_equal(other.row_size,self.column_size,"pre-condition: the matrix being multiplied by this one does not have the same number of rows as this does columns")
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
        assert_equal(result.row_size,self.row_size,"post-condition: result of matrix multiplication does not have the same number of rows as the original")
        assert_equal(result.column_size,other.column_size,"post-condition: result of matrix multiplication does not have the same number of columns as what the original was multiplied by")
        assert_equal(result.toBaseMatrix,self.toBaseMatrix*other.toBaseMatrix,"post-condition: wrong result in matrix multiply")
      elsif other.is_a? Numeric
        assert_equal(result.row_size,self.row_size,"post-condition: result of scalar multiplication does not have the same number of rows as the original matrix")
        assert_equal(result.column_size,self.column_size,"post-condition: result of scalar multiplication does not have the same number of columns as the original matrix")
        assert_equal(result.toBaseMatrix,self.toBaseMatrix*other,"post-conditions: wrong result in scalar multiply")
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
      assert((other.respond_to? :[]), "pre-condition: other matrix in an elementwise multiply must respond to \"[]\"")
      _invariants
      assert_equal(self.row_size,other.row_size, "pre-condition: the row sizes must be equal on an elementwise multiply")
      assert_equal(self.column_size,other.column_size, "pre-condition: the column sizes must be equal on an elementwise multiply")
    end


    result = self.clone
    self.each_with_index {|index,val|
      result.put(index, val * other[index] )
    }

    # post-conditions and invariants
    if debug
      _invariants
      assert_equal(result.toBaseMatrix,Matrix.build(self.row_size,self.column_size) {|x,y| self[x,y] * other[x,y]}, "post-condition: the elements in the resultant matrix after an elementwise multiply are wrong")
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
      assert_equal(result.internalRepItemCount,self.internalRepItemCount,"post-condition: vertically mirrored matrix has a different number of items than the original")
      result.each_with_index { |index,val|
        row = index[0]
        col = index[1]
        assert_equal(val,self[row,self.column_size-1-col],"post-condition: matrix has not been properly horizontally flipped")
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
      assert_equal(result.internalRepItemCount,self.internalRepItemCount,"post-condition: vertically mirrored matrix has a different number of items than the original")
      result.each_with_index { |index,val|
        row = index[0]
        col = index[1]
        assert_equal(val,self[self.row_size-1-row,col],"post-condition: matrix has not been properly vertically flipped")
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
    prng = Random.new()
    # the sparse matrix internal representation should never have
    # more items than zeros in the matrix it represents
    representedMatrix = self.toBaseMatrix
    nonzeros = 0
    representedMatrix.each { |item|
      if item != 0
        nonzeros += 1
      end
    }
    assert_equal(self.internalRepItemCount, nonzeros, "invariant failure: the sparse matrix internal representation does not have the same number of items as the matrix it represents")

    # there should never be any zero values in the internal matrix
    zeros = 0
    self.each_with_index { |item, index| zeros += 1 if item == 0 }
    assert_equal(zeros,0,"invariant failure: there are zero values in the internal representation of the matrix")

    # make sure the sparse matrix is in the bounds of the original
    maxRow = nil
    self.each_with_index { |index, item|
      unless maxRow.nil?
        maxRow = [maxRow, index[0]].max
      else
        maxRow = index[0]
      end
    }
    assert(maxRow <= representedMatrix.row_size, "invariant failure: the sparse matrix is not in the bounds of the matrix it represents")

    minRow = nil
    self.each_with_index { |item, index|
      unless minRow.nil?
        minRow = [minRow, index[0]].min
      else
        minRow = index[0]
      end
    }
    assert(minRow >= 0, "invariant failure: the sparse matrix is not in the bounds of the matrix it represents")

    maxCol = nil
    self.each_with_index { |item, index|
      unless maxCol.nil?
        maxCol = [maxCol, index[1]].max
      else
        maxCol = index[1]
      end
    }
    assert(maxCol <= representedMatrix.column_size, "invariant failure: the sparse matrix is not in the bounds of the matrix it represents")

    minCol = nil
    self.each_with_index { |item, index|
      unless minCol.nil?
        minCol = [minCol, index[1]].min
      else
        minCol = index[1]
      end
    }
    assert(minCol >= 0, "invariant failure: the sparse matrix is not in the bounds of the matrix it represents")

    # Insure that our matrix starts at 0,0 (as opposed to 1,1, for example)
    assert_equal(self[0,0],representedMatrix[0,0], "invariant failure: the sparse matrix does not appear to be zero indexed")

    # The transpose of a transpose is itself
    assert_equal(self.transpose.transpose,self, "invariant failure: the transpose of the transpose of the sparse matrix is not itself")

    # a matrix plus a scalar, minus the same scalar is itself
    assert_equal(self+5-5,self, "invariant failure: this matrix plus a scalar minus a scalar is not returning the same matrix")

    # a matrix added to a matrix, then subtracted by the same matrix is itself
    # (and vice versa)
    diffMatrixOriginal = Matrix.build(self.row_size, self.column_size) { |row,col| prng.rand(10) }
    diffMatrix = SparseMatrix.create(diffMatrixOriginal)
    assert_equal(self + diffMatrix -diffMatrix ,self, "invariant failure: this matrix plus a matrix minus a the matrix is not producing the same result")
    assert_equal(self - diffMatrix + diffMatrix ,self, "invariant failure: this matrix plus a matrix minus a the matrix is not producing the same result")

    # The inverse of the determinant is the same as the determinant of the inverse
    #begin
    #  assert_equal(sparseMatrix.inv.det,1.0/sparseMatrix.det)
    #rescue NotInvertibleError
    #end

    # if you switch two rows in a matrix back and forth, you will end with the same matrix
    assert_equal(self.rowSwitch(2,3,0).rowSwitch(2,3,0),self, "invariant failure: switching two rows in this matrix does not yield the original matrix")


    # if you mirror the matrix twice (on either axis), it should be the same as the original
    assert_equal(self.flipHorizontal.flipHorizontal,self, "invariant failure: this sparse matrix mirrored horizontally does not yield the original matrix")
    assert_equal(self.flipVertical.flipVertical,self, "invariant failure: this sparse matrix mirrored vertically does not yield the original matrix")

    # rotations that total to 360 degrees will be the same as the original matrix
    assert_equal(self.rotate(0).rotate(0).rotate(0).rotate(0),self, "invariant failure: 4 rotations of 90 degrees doesn't yield the same result")
    assert_equal(self.rotate(1).rotate(1),self, "invariant failure: 2 rotations of 180 degrees doesn't yield the same result")
    assert_equal(self.rotate(2).rotate(0),self, "invariant failure: 1 rotations of 270 degrees and 1 rotation of 90 degrees doesn't yield the same result")

    # the inverse of the inverse of a matrix is itself
    # (this is only true for invertable matrices)
    #begin
    #  assert_equal(sparseMatrix.inv.inv,sparseMatrix)
    #rescue NotInvertibleError
    #else
    #  assert(false)
    #end

  end

end