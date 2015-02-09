require_relative "../lib/SparseMatrix/SparseMatrix"
require_relative "../lib/SparseMatrix/NotInvertibleError"
require "test/unit"
require "matrix"

class TestSparseMatrix < Test::Unit::TestCase

  # size of our matrix
  MAT_ROWS = 100
  MAT_COLS = 100
  # percent of values that are non-zero (approximate)
  SPARSITY = 20
  # seed for our random number generator
  SEED = 0
  # max value in our array of integers
  MAX_VAL = 100

  def setup
    # random number generator. We want our tests to be consistent, so
    # we set it up with a constant seed
    @prng = Random.new(SEED)

    # create the matrices for our tests
    @originalMatrix = Matrix.build(MAT_ROWS,MAT_COLS) { |row,col|
      if @prng.rand(100) < SPARSITY
        @prng.rand(MAX_VAL)
      else
        0
      end
    }
    @sparseMatrix = SparseMatrix.create(@originalMatrix)

    # use to compare the changed matrix
    @oldSparseMatrix = @sparseMatrix.clone

  end

  def teardown
    # nothing to do here
  end

  # modify non-zero values in matrix by supplying an index
  # and a new value
  def test_put

    # test values
    nonZeroIndices = []
    @sparseMatrix.each_with_index { |index, val| if val != 0
                                                   nonZeroIndices.push(index)
                                                 end }

    index = nonZeroIndices[@prng.rand(nonZeroIndices.size)]
    val = @prng.rand(MAX_VAL)

    # pre-conditions and invariants
    assert(_inbounds(index,@sparseMatrix))
    assert(val.is_a? Numeric)
    assert_not_equal(@sparseMatrix[index],0)
    #_invariants(@sparseMatrix,@originalMatrix)

    # run the command
    @sparseMatrix.put(index,val)

    # post-conditions and invariants
    #_invariants(@sparseMatrix,@originalMatrix)
    assert_equal( @sparseMatrix[index], val )
    assert(@sparseMatrix.include?(val))
    assert_equal(@sparseMatrix.internalRepItemCount,@oldSparseMatrix.internalRepItemCount)

  end

  # modify zero values in matrix by supplying an index
  # and a new value
  def test_put_in_zero

    # test values
    zeroIndices = []
    (0..MAT_ROWS).each { |i|
      (0..MAT_COLS).each { |j|
        if @sparseMatrix[i,j] == 0
          zeroIndices.push([i,j])
        end
      }
    }

    index = zeroIndices[@prng.rand(zeroIndices.size)]
    val = @prng.rand(MAX_VAL)

    # pre-conditions and invariants
    assert(_inbounds(index,@sparseMatrix))
    assert(val.is_a? Numeric)
    assert_equal(@sparseMatrix[index],0)
    #_invariants(@sparseMatrix,@originalMatrix)

    # run the command
    @sparseMatrix.put(index,val)

    # post-conditions and invariants
    #_invariants(@sparseMatrix,@originalMatrix)
    assert_equal( @sparseMatrix[index], val )
    assert(@sparseMatrix.include?(val))
    assert_equal(@sparseMatrix.internalRepItemCount,@oldSparseMatrix.internalRepItemCount+1)

  end

  # transpose the matrix
  def test_transpose

    # pre-conditions and invariants
    #_invariants(@sparsematrix,@originalMatrix)

    # do the operation
    transposedMatrix = @sparseMatrix.transpose

    #post-conditions and invariants
    #_invariants(@sparsematrix,@originalMatrix)
    assert_equal(@sparseMatrix.row_size,transposedMatrix.column_size)
    assert_equal(@sparseMatrix.column_size,transposedMatrix.row_size)

    (0..@sparseMatrix.row_size-1).each { |i|
      (0..@sparseMatrix.column_size-1).each { |j|
        assert_equal(@sparseMatrix[i,j],transposedMatrix[j,i])
      }
    }

  end

  # add two matrices together
  def test_add

    # matrix to add
    baseMatrix = Matrix.build(MAT_ROWS,MAT_COLS) { |row,col|
      if @prng.rand(100) < SPARSITY
        @prng.rand(MAX_VAL)
      else
        0
      end
    }
    addMatrix = SparseMatrix.create(baseMatrix)

    # pre-conditions and invariants
    assert(addMatrix.is_a? SparseMatrix)
    assert_equal(addMatrix.row_size,@sparseMatrix.row_size)
    assert_equal(addMatrix.column_size,@sparseMatrix.column_size)
    #_invariants(@sparseMatrix,@oldSparseMatrix)

    # do the operation
    result = @sparseMatrix + addMatrix

    # post-conditions and invariants
    #_invariants(@sparseMatrix,@oldSparseMatrix)
    assert_equal(result.row_size,@sparseMatrix.row_size)
    assert_equal(result.column_size,@sparseMatrix.column_size)
    assert_equal(result.toBaseMatrix,baseMatrix+@originalMatrix)

  end


  # subtract one matrix from another
  def test_subtract

    # matrix to subtract
    baseMatrix = Matrix.build(MAT_ROWS,MAT_COLS) { |row,col|
      if @prng.rand(100) < SPARSITY
        @prng.rand(MAX_VAL)
      else
        0
      end
    }
    subMatrix = SparseMatrix.create(baseMatrix)

    # pre-conditions and invariants
    assert(subMatrix.is_a? SparseMatrix)
    assert_equal(subMatrix.row_size,@sparseMatrix.row_size)
    assert_equal(subMatrix.column_size,@sparseMatrix.column_size)
    #_invariants(@sparseMatrix,@oldSparseMatrix)

    # do the operation
    result = @sparseMatrix - subMatrix

    # post-conditions and invariants
    #_invariants(@sparseMatrix,@oldSparseMatrix)
    assert_equal(result.row_size,@sparseMatrix.row_size)
    assert_equal(result.column_size,@sparseMatrix.column_size)
    assert_equal(result.toBaseMatrix,@originalMatrix-baseMatrix)

  end

  # add a scalar value to the matrix
  def test_add_scalar
    # value to add
    val = 5

    # pre-condition and invariants
    assert(val.is_a? Numeric)
    #_invariants(@sparseMatrix,@oldSparseMatrix)

    # do the operation
    result = @sparseMatrix + val

    # post-conditions and invariants
    #_invariants(@sparseMatrix,@oldSparseMatrix)
    assert_equal(result.row_size,@sparseMatrix.row_size)
    assert_equal(result.column_size,@sparseMatrix.column_size)
    assert_equal(result.toBaseMatrix,Matrix.build(@originalMatrix.row_size,@originalMatrix.column_size){|x,y| @originalMatrix[x,y]+val})
    assert_equal(@sparseMatrix,@oldSparseMatrix)


  end

  # subtract a scalar value from the matrix
  def test_sub_scalar
    # value to subtract
    val = 5

    # pre-condition and invariants
    assert(val.is_a? Numeric)
    #_invariants(@sparseMatrix,@oldSparseMatrix)

    # do the operation
    result = @sparseMatrix - val

    # post-conditions and invariants
    #_invariants(@sparseMatrix,@oldSparseMatrix)
    assert_equal(result.row_size,@sparseMatrix.row_size)
    assert_equal(result.column_size,@sparseMatrix.column_size)
    assert_equal(result.toBaseMatrix,Matrix.build(@originalMatrix.row_size,@originalMatrix.column_size){|x,y| @originalMatrix[x,y]-val})
    assert_equal(@sparseMatrix,@oldSparseMatrix)


  end

  # test matrix multiplication
  def test_mult
    # matrix to multiply
    newMatRows = @sparseMatrix.column_size
    newMatCols = 10
    baseMatrix = Matrix.build(newMatRows,newMatCols) { |row,col|
      if @prng.rand(100) < SPARSITY * 2
        @prng.rand(MAX_VAL)
      else
        0
      end
    }
    multMatrix = SparseMatrix.create(baseMatrix)

    result = @sparseMatrix * multMatrix

    assert_equal(result.row_size,@sparseMatrix.row_size)
    assert_equal(result.column_size,multMatrix.column_size)
    assert_equal(result.toBaseMatrix,@originalMatrix*baseMatrix)

  end

  # test the flip horizontal function
  def test_flip_horizontal

    result = @sparseMatrix.flipHorizontal
    
    assert_equal(result.internalRepItemCount,@sparseMatrix.internalRepItemCount)
    
    result.each_with_index { |index,val|
      row = index[0]
      col = index[1]
      assert_equal(val,@sparseMatrix[row,@sparseMatrix.column_size-1-col])
    }

  end

  # test the flip vertical function
  def test_flip_vertical

    result = @sparseMatrix.flipVertical

    assert_equal(result.internalRepItemCount,@sparseMatrix.internalRepItemCount)

    result.each_with_index { |index,val|
      row = index[0]
      col = index[1]
      assert_equal(val,@sparseMatrix[@sparseMatrix.row_size-1-row,col])
    }

  end

  # test scalar multiplication
  def test_scalar_mult
    # value to multiply
    val = 5

    result = @sparseMatrix * val

    assert_equal(result.row_size,@sparseMatrix.row_size)
    assert_equal(result.column_size,@sparseMatrix.column_size)
    assert_equal(result.toBaseMatrix,@originalMatrix*val)

  end

  # test elementwise multiplication
  def test_element_mult
    # matrix to multiply
    baseMatrix = Matrix.build(@sparseMatrix.row_size,@sparseMatrix.column_size) { |row,col|
      if @prng.rand(100) < SPARSITY * 2
        @prng.rand(MAX_VAL)
      else
        0
      end
    }
    multMatrix = SparseMatrix.create(baseMatrix)

    result = @sparseMatrix.elementMult(multMatrix)

    assert_equal(result.row_size,@sparseMatrix.row_size)
    assert_equal(result.column_size,@sparseMatrix.column_size)
    assert_equal(result.toBaseMatrix,Matrix.build(@sparseMatrix.row_size,@sparseMatrix.column_size) {|x,y| @sparseMatrix[x,y]*baseMatrix[x,y]})
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
  # +sparseMatrix+:: the sparse matrix
  # +representedMatrix+:: the full matrix that the sparse matrix
  #   is representing
  def _invariants(sparseMatrix,representedMatrix)

    # the sparse matrix internal representation should never have
    # more items than zeros in the matrix it represents
    nonzeros = 0
    representedMatrix.each { |item|
      if item != 0
        nonzeros += 1
      end
    }
    assert_equal(sparseMatrix.internalRepItemCount, nonzeros)

    # there should never be any zero values in the internal matrix
    zeros = 0
    sparseMatrix.each_with_index { |item, index| zeros += 1 if item == 0 }
    assert_equal(zeros,0)

    # make sure the sparse matrix is in the bounds of the original
    maxRow = nil
    sparseMatrix.each_with_index { |index, item|
      unless maxRow.nil?
        maxRow = [maxRow, index[0]].max
      else
        maxRow = index[0]
      end
    }
    assert(maxRow <= representedMatrix.row_size)

    minRow = nil
    sparseMatrix.each_with_index { |item, index|
      unless minRow.nil?
        minRow = [minRow, index[0]].min
      else
        minRow = index[0]
      end
    }
    assert(minRow >= 0)

    maxCol = nil
    sparseMatrix.each_with_index { |item, index|
      unless maxCol.nil?
        maxCol = [maxCol, index[1]].max
      else
        maxCol = index[1]
      end
    }
    assert(maxCol <= representedMatrix.column_size)

    minCol = nil
    sparseMatrix.each_with_index { |item, index|
      unless minCol.nil?
        minCol = [minCol, index[1]].min
      else
        minCol = index[1]
      end
    }
    assert(minCol >= 0)

    # Insure that our matrix starts at 0,0 (as opposed to 1,1, for example)
    assert_equal(sparseMatrix[0,0],representedMatrix[0,0])

    # The transpose of a transpose is itself
    assert_equal(sparseMatrix.transpose.transpose,sparseMatrix)

    # a matrix plus a scalar, minus the same scalar is itself
    assert_equal(sparseMatrix+5-5,sparseMatrix)

    # a matrix added to a matrix, then subtracted by the same matrix is itself
    # (and vice versa)
    diffMatrixOriginal = Matrix.build(sparseMatrix.row_size, sparse_matrix.column_size) { |row,col| @prng.rand(10) }
    diffMatrix = SparseMatrixFactory.create(diffMatrixOriginal)
    assert_equal(sparseMatrix.add(diffMatrix).subtract(diffMatrix),sparseMatrix)
    assert_equal(sparseMatrix.subtract(diffMatrix).add(diffMatrix),sparseMatrix)

    # The inverse of the determinant is the same as the determinant of the inverse
    assert_equal(sparseMatrix.inverse.determinant,sparseMatrix.determinant.inverse)

    # if you switch two rows in a matrix back and forth, you will end with the same matrix
    assert_equal(sparseMatrix.rowSwitch(2,3,0).rowSwitch(2,3,0),sparseMatrix)

    # if you mirror the matrix twice (on either axis), it should be the same as the original
    assert_equal(sparseMatrix.flip(0).flip(0),sparseMatrix)
    assert_equal(sparseMatrix.flip(1).flip(1),sparseMatrix)

    # rotations that total to 360 degrees will be the same as the original matrix
    assert_equals(sparseMatrix.rotate(0).rotate(0).rotate(0).rotate(0),sparseMatrix)
    assert_equals(sparseMatrix.rotate(1).rotate(1),sparseMatrix)
    assert_equals(sparseMatrix.rotate(2).rotate(0),sparseMatrix)

    # the inverse of the inverse of a matrix is itself
    # (this is only true for invertable matrices)
    begin
      assert_equal(sparseMatrix.inverse.inverse,sparseMatrix)
    rescue NotInvertibleError
    else
      assert(false)
    end

  end

end