require_relative "../lib/SparseMatrix/SparseMatrix"
require_relative "../lib/SparseMatrix/NotInvertibleError"
require "test/unit"

class TestSimpleNumber < Test::Unit::TestCase

  def test_
  end

  # test the invariants
  # +sparseMatrix+:: the sparse matrix
  # +representedMatrix+:: the full matrix that the sparse matrix
  #   is representing
  def _invariants(sparseMatrix,representedMatrix)

    # the sparse matrix internal representation should never have
    # more items than zeros in the matrix it represents
    nonzeros = 0
    representedMatrix.each { |row| row.each { |item| nonzeros += 1 }}
    assert_equal(matrix.internalRepItemCount, nonzeros)

    # there should never be any zero values in the internal matrix
    zeros = 0
    sparseMatrix.each_with_index { |item, index| zeros += 1 if item == 0 }
    assert_equal(zeros,0)

    # make sure the sparse matrix is in the bounds of the original
    sparseMatrix.each_with_index { |item, index|
      if defined? maxRow
        maxRow = max(maxRow, index[0])
      else
        maxRow = index[0]
      end
    }
    assert(maxRow <= representedMatrix.row_size)

    sparseMatrix.each_with_index { |item, index|
      if defined? minRow
        minRow = min(minRow, index[0])
      else
        minRow = index[0]
      end
    }
    assert(minRow >= 0)

    sparseMatrix.each_with_index { |item, index|
      if defined? maxCol
        maxCol = max(maxCol, index[1])
      else
        maxCol = index[1]
      end
    }
    assert(maxCol <= representedMatrix.column_size)

    sparseMatrix.each_with_index { |item, index|
      if defined? minCol
        minCol = min(minCol, index[1])
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
    diffMatrixOriginal = Matrix.build(sparseMatrix.row_size, sparse_matrix.column_size) { |row,col| rand }
    diffMatrix = SparseMatrixFactory.createSparseMatrix(diffMatrixOriginal)
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