require_relative "../lib/SparseMatrix/SparseMatrix"
require_relative '../lib/SparseMatrix/NotInvertibleError'
require "test/unit"
require "matrix"


class TestSparseMatrix < Test::Unit::TestCase

  # set to something else if you don't want to do contract checks
  DEBUG = SparseMatrix.DEBUG_FLAG

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

  def test_size
    spar = SparseMatrix.create(123,456)
    siz = spar.size
    assert_equal(siz[0],123, "row size error")
    assert_equal(siz[1],456, "col size error")
  end

  def test_rowSwitch
    mat1 = SparseMatrix.create(Matrix[[1,2],[3,4]])
    mat2 = Matrix[[3,4],[1,2]]
    mat3 = mat1.rowSwitch(0,1,0)
    assert_equal(mat3.toBaseMatrix, mat2, "rowSwitch fail")
  end

  def test_rowOper
    mat = SparseMatrix.create(Matrix[[1,2],[3,4]])
    mat_add = Matrix[[4,6],[3,4]]
    mat_mult = Matrix[[3,8],[3,4]]
    assert_equal(mat.rowOper(0,1,:+).toBaseMatrix,mat_add,"add")
    assert_equal(mat.rowOper(0,1,:*).toBaseMatrix,mat_mult,"mult")
  end

  def test_row
    mat = SparseMatrix.create(Matrix[[1,2,3,4],[5,6,7,8]])
    row = mat.row(0)
    assert_equal(row,[1,2,3,4],"row error")
  end

  def test_rotate
    mat1 = SparseMatrix.create(Matrix[[1,2],[3,4]])
    mat4 = Matrix[[3,1],[4,2]]
    mat3 = Matrix[[4,3],[2,1]]
    mat2 = Matrix[[2,4],[1,3]]
    assert_equal(mat1.rotate(0).toBaseMatrix,mat2,"90 degree rotate fail")
    assert_equal(mat1.rotate(1).toBaseMatrix,mat3,"180 degree rotate fail")
    assert_equal(mat1.rotate(2).toBaseMatrix,mat4,"270 degree rotate fail")
  end

  def test_rank
    mat = SparseMatrix.create(Matrix[[2,2,-1],[4,0,2],[0,6,-1]])
    mat2 = SparseMatrix.create(Matrix[[2,2,-1,1],[4,0,2,2],[0,6,-1,4]])
    assert_equal(mat.rank,3)
    assert_equal(mat2.rank,3)
  end

  def test_det
    mat = SparseMatrix.create(Matrix[[6,1,1],[4,-2,5],[2,8,7]])
    assert_equal(mat.det,-306,"det error")
  end

  def test_inv
    mat = SparseMatrix.create(Matrix[[1,2,3],[0,4,5],[1,0,6]])
    mat_inv = Matrix[[(12.0/11.0).round(10),(-6.0/11.0).round(10),(-1.0/11.0).round(10)],[(5.0/22.0).round(10),(3.0/22.0).round(10),(-5.0/22.0).round(10)],[(-2.0/11.0).round(10),(1.0/11.0).round(10),(2.0/11.0).round(10)]]
    assert_equal(mat.inv.toBaseMatrix,mat_inv,"inverse fail")
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
    _invariants(@sparseMatrix,@originalMatrix)

    # run the command
    @sparseMatrix.put(index,val,DEBUG)

    # post-conditions and invariants
    _invariants(@sparseMatrix,@originalMatrix)
    assert_equal( @sparseMatrix[index], val )
    assert(@sparseMatrix.include?(val))
    assert_equal(@sparseMatrix.internalRepItemCount,@oldSparseMatrix.internalRepItemCount)

  end


  # test the submatrix function
  def test_sub_matrix

    testMat = Matrix.build(5,5) {|x,y| y}
    testSp = SparseMatrix.create(testMat)
    testSp.subMatrix([1],[1,3])

    # indices to remove
    nonZeroIndices = []
    @sparseMatrix.each_with_index { |index, val| if val != 0
                                                   nonZeroIndices.push(index)
                                                 end }
    rows = [nonZeroIndices[0][0], nonZeroIndices[1000][0], nonZeroIndices[200][0]]
    cols = [nonZeroIndices[0][1], nonZeroIndices[1][1], nonZeroIndices[2][1]]
    ret = @sparseMatrix.subMatrix(rows,cols,DEBUG)

    assert_equal(ret.row_size,@sparseMatrix.row_size-3)
    assert_equal(ret.column_size,@sparseMatrix.column_size-3)

    starti = 0
    (0..@sparseMatrix.row_size-1).each { |i|
      startj = 0
      unless i == rows[0] or i == rows[1] or i == rows[2]
        (0..@sparseMatrix.column_size-1).each { |j|
          unless j == cols[0] or j == cols[1] or j == cols[2]
            assert_equal(@sparseMatrix[i,j],ret[starti,startj])
            startj += 1
          end
        }
        starti += 1
      end
    }
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
    _invariants(@sparseMatrix,@originalMatrix)

    # run the command
    @sparseMatrix.put(index,val,DEBUG)

    # post-conditions and invariants

    assert_equal( @sparseMatrix[index], val )
    assert(@sparseMatrix.include?(val))
    assert_equal(@sparseMatrix.internalRepItemCount,@oldSparseMatrix.internalRepItemCount+1)
    _invariants(@sparseMatrix,@sparseMatrix.toBaseMatrix)

  end

  # transpose the matrix
  def test_transpose

    # pre-conditions and invariants
    _invariants(@sparseMatrix,@originalMatrix)

    # do the operation
    transposedMatrix = @sparseMatrix.transpose(DEBUG)

    #post-conditions and invariants
    _invariants(@sparseMatrix,@originalMatrix)
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
    _invariants(@sparseMatrix,@oldSparseMatrix)

    # do the operation
    result = @sparseMatrix.send(:+, addMatrix, DEBUG)

    # post-conditions and invariants
    _invariants(@sparseMatrix,@oldSparseMatrix)
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
    _invariants(@sparseMatrix,@oldSparseMatrix)

    # do the operation
    result = @sparseMatrix.send(:-, subMatrix, DEBUG)

    # post-conditions and invariants
    _invariants(@sparseMatrix,@oldSparseMatrix)
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
    _invariants(@sparseMatrix,@oldSparseMatrix)

    # do the operation
    result = @sparseMatrix.send(:+,val,DEBUG)

    # post-conditions and invariants
    _invariants(@sparseMatrix,@oldSparseMatrix)
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
    _invariants(@sparseMatrix,@oldSparseMatrix)

    # do the operation
    result = @sparseMatrix.send(:-,val,DEBUG)

    # post-conditions and invariants
    _invariants(@sparseMatrix,@oldSparseMatrix)
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

    result = @sparseMatrix.send(:*,multMatrix,DEBUG)

    assert_equal(result.row_size,@sparseMatrix.row_size)
    assert_equal(result.column_size,multMatrix.column_size)
    assert_equal(result.toBaseMatrix,@originalMatrix*baseMatrix)

  end

  # test the flip horizontal function
  def test_flip_horizontal

    result = @sparseMatrix.flipHorizontal(DEBUG)
    
    assert_equal(result.internalRepItemCount,@sparseMatrix.internalRepItemCount)
    
    result.each_with_index { |index,val|
      row = index[0]
      col = index[1]
      assert_equal(val,@sparseMatrix[row,@sparseMatrix.column_size-1-col])
    }

  end

  # test the flip vertical function
  def test_flip_vertical

    result = @sparseMatrix.flipVertical(DEBUG)

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

    result = @sparseMatrix.send(:*,val,DEBUG)

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

    result = @sparseMatrix.elementMult(multMatrix,DEBUG)

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
    diffMatrixOriginal = Matrix.build(sparseMatrix.row_size, sparseMatrix.column_size) { |row,col| @prng.rand(10) }
    diffMatrix = SparseMatrix.create(diffMatrixOriginal)
    assert_equal(sparseMatrix + diffMatrix -diffMatrix ,sparseMatrix)
    assert_equal(sparseMatrix - diffMatrix + diffMatrix ,sparseMatrix)

    # The inverse of the determinant is the same as the determinant of the inverse
    #begin
    #  assert_equal(sparseMatrix.inv.det,1.0/sparseMatrix.det)
    #rescue NotInvertibleError
    #end

    # if you switch two rows in a matrix back and forth, you will end with the same matrix
    assert_equal(sparseMatrix.rowSwitch(2,3,0).rowSwitch(2,3,0),sparseMatrix)


    # if you mirror the matrix twice (on either axis), it should be the same as the original
    assert_equal(sparseMatrix.flipHorizontal.flipHorizontal,sparseMatrix)
    assert_equal(sparseMatrix.flipVertical.flipVertical,sparseMatrix)

    # rotations that total to 360 degrees will be the same as the original matrix
    assert_equal(sparseMatrix.rotate(0).rotate(0).rotate(0).rotate(0),sparseMatrix)
    assert_equal(sparseMatrix.rotate(1).rotate(1),sparseMatrix)
    assert_equal(sparseMatrix.rotate(2).rotate(0),sparseMatrix)

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