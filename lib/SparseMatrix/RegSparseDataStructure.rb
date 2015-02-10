# The internal structure for regular sparse matrices

require "matrix"

class RegSparseDataStructure < AbstractDataStructure

  # Constructor. args can be:
  #   a single Matrix, in which case the matrix will be coppied in
  #   a list of integers, which will represent the size of the dimensions, and create a matrix of zeros
  def initialize(*args)
    @map = Hash.new()
    # Case in which we are creating an empty matrix of size
    if args[0].is_a? Integer
      # assume only 2 dimensions
      if args.size == 2
        @rows = args[0]
        @columns = args[1]
        @map = _createMap(@rows)
      else
        raise "matrices of dimensions other than 2 are not currently supported"
      end
    elsif args.size == 1
      _copyMatrix(args[0])
    else
      raise "invalid initialization arguments"
    end

  end

  def _createMap(rows)
    map = Hash.new()
    (0..rows-1).each {|i| map[i] = Hash.new(0) }
    return map
  end

  # Copy the input matrix into this matrix
  def _copyMatrix(matrix)

    @rows = matrix.row_size
    @columns = matrix.column_size

    # create an entry for each row, and default the values to 0
    @map = _createMap(@rows)

    # enter non zero values
    matrix.each_with_index { |val, row, col|
      if val != 0
        put([row,col],val)
      end
    }
  end

  # put val into index
  def put(index,val)
    # duplicate index so that it doesn't change
    dupIndex = index.clone
    dims = dupIndex.size

    # TODO: current implementation is only for 2d arrays
    unless dims == 2
      raise "index has the wrong number of values (#{dims} instead of 2)"
    end
    unless dupIndex[0] >= 0 and dupIndex[0] < @rows and dupIndex[1] >= 0 and dupIndex[1] < @columns
      raise "index #{dupIndex} is out of bounds"
    end

    # note: from http://stackoverflow.com/questions/14294751/how-to-set-nested-hash-in-ruby-dynamically
    _putIntoMap(@map,index,val)

    #dupIndex.inject(@map, :fetch)[last] = val unless val == 0 and self[index] == 0 # don't add new rows for zeros

  end

  def _putIntoMap(map,index,val)
    dupIndex = index.clone
    last = dupIndex.pop
    if val == 0
      begin
        dupIndex.inject(map, :fetch).delete(last)
      rescue NoMethodError
        # the key is already zero
      end
    else
      dupIndex.inject(map, :fetch)[last] = val
    end
  end

  def clone
    newData = RegSparseDataStructure.new(@rows,@columns)
    self.each_with_index { |index,val|
      newData[index] = val
    }
    return newData
  end

  def []=(*opts)
    if opts.size == 2
      self.put(opts[0],opts[1])
    else
      self.put(opts[0..-2],opts[-1])
    end
  end

  # iterate through all the elements in the array
  def each_with_index(&block)
    @map.each {|key1,val1|
      unless val1 == nil
        val1.each {|key2,val2|
          yield([key1,key2],val2)
        }
      end
    }
    #_map_iterate(@map,[],&block)
  end

  # Iterate through the given map recursively, and yield to the block
  def _map_iterate(map, lastIndices, &block)
    map.each { |index, val|
      if val.is_a? Hash
        _map_iterate(val,lastIndices+[index],&block)
      else
        yield(lastIndices+[index],val)
      end
    }
  end

  def getRowSize
    return @rows
  end

  def getColSize
    return @columns
  end

  def [](*index)
    if index[0].kind_of?(Array)
      index = index[0]
    end

    # return what's at the index. If nothing's there, return 0 (the default value)
    begin
      return index.inject(@map, :[])
    rescue NoMethodError
      return 0
    end
  end

  def rowCount
    count = 0
    self.each_with_index {|index,val| count += 1 }
    return count
  end

  # transpose the matrix
  def transpose

    # we are just going to overwrite the hash
    newHash = Hash.new()

    # transpose the vals from the old hash to the new one
    self.each_with_index { |index,val|
      first = index[0]
      last = index[1]
      # add the second level of the hash if necessary
      unless newHash.has_key? last
        newHash[last] = Hash.new(0)
      end
      newHash[last][first] = val
    }
    @map = newHash

    # the shape has changed
    oldRows = @rows
    @rows = @columns
    @columns = oldRows
    return self
  end

  # add the value from another array to this one, and return the result
  def +(other)
    if other.is_a? RegSparseDataStructure
      return _addToReg(other)
    elsif other.is_a? Numeric
      return _addToScalar(other)
    end
    raise "object to be added is of incompatible type"
  end

  # remove the value from another array from this one, and return the result
  def -(other)
    if other.is_a? RegSparseDataStructure
      return _subFromReg(other)
    elsif other.is_a? Numeric
      return _subFromScalar(other)
    end
  end

  # multiply a scalar by this matrix
  def *(other)
    selfDup = self.clone
    self.each_with_index { |index,val|
      selfDup[index] = val*other
    }
    return selfDup
  end

  # flip this matrix horizontally
  def flipHorizontal

    newMap = _createMap(@rows)
    self.each_with_index {|index,val|
      row = index[0]
      col = index[1]
      _putIntoMap(newMap,[row,@columns-1-col],val)
    }

    @map = newMap

  end

  # Create a submatrix of this, removing rows and cols
  def subMatrix(rows,cols)
    rowsdup = rows.uniq
    colsdup = cols.uniq
    # make sure we are going largest to smallest
    rowsdup = rowsdup.sort {|x,y| y <=> x}
    colsdup = colsdup.sort {|x,y| y <=> x}



    rowsdup.each { |r|
      @map.delete(r)
      # move all larger indices down
      (r..@rows-1).each {|i|
        @map[i] = @map[i+1]
      }
    }
    colsdup.each{ |c|
      @map.each { |key,val|
        unless val.nil?
          val.delete(c)
          # move all larger indices down
          (c..@columns-1).each {|i|
            unless val[i+1] == 0
              val[i] = val[i+1]
            else
              val.delete(i)
            end
          }
        end
      }
    }

    # readjust the lengths
    @rows -= rowsdup.length
    @columns -= colsdup.length
    return self
  end

  # flip this matrix horizontally
  def flipVertical

    newMap = _createMap(@rows)
    self.each_with_index {|index,val|
      row = index[0]
      col = index[1]
      _putIntoMap(newMap,[@rows-1-row,col],val)
    }

    @map = newMap

  end

  def _addToReg(other)
    otherDup = other.clone
    self.each_with_index {|index,val|
      otherDup[index] = otherDup[index] + val
    }
    return otherDup
  end

  def _addToScalar(other)
    selfDup = self.clone
    (0..@rows-1).each { |i|
      (0..@columns-1).each { |j|
        selfDup[i,j] = selfDup[i,j] + other
      }
    }
    return selfDup
  end

  def _subFromReg(other)
    otherDup = self.clone
    other.each_with_index { |index,val|
      otherDup[index] = otherDup[index] - val
    }
    return otherDup
  end

  def _subFromScalar(other)
    selfDup = self.clone
    (0..@rows-1).each { |i|
      (0..@columns-1).each { |j|
        selfDup[i,j] = selfDup[i,j] - other
      }
    }
    return selfDup
  end

  # return the ruby Matrix representation of the array
  def toBaseMatrix
    mat = Matrix.build(@rows,@columns) { |i,j| self[i,j] }
    return mat
  end

  def size
    return [@rows,@columns]
  end

  def det
    raise "Matrix Not Square" unless @rows == @columns
    if self.getColSize == 1 and self.getRowSize == 1
      return 1.0/self[0,0]
    elsif self.getColSize == 2 and self.getRowSize == 2
      return (self[0,0] * self[1,1]) - (self[0,1] * self[1,0])
    elsif self.getColSize > 2 and self.getRowSize > 2
      result = 0
      flip = 1

      (0..@columns-1).each{|i|
       mat = self.clone
       mat.subMatrix([0],[i])
       result = result + flip * self[0][i] * mat.det
       flip = -1 * flip }
      return result
    end
  end

  def rowSwitch(index1, index2, dim)
    if dim == 0
      temp = @map[index1]
      @map[index1] = @map[index2]
      @map[index2] = temp
    elsif dim == 1
      (0..getRowSize).each{|i|
        temp = @map[i][index1]
        @map[i][index1] = @map[i][index2]
        @map[i][index2] = temp
      }
    else
          raise "dim is 0 for row, and 1 for column"
    end
    return self
  end

  def col(index)
    mat = []
    (0..self.getRowSize).each {|i| mat[i] = @mat[i][index]}
    return mat
  end

  def row(index)
    dat = @map.clone
    mat = []
    (0..self.getColSize-1).each{|i| mat[i] = dat[index][i]}
    return mat
  end

  def rotate(val) #http://stackoverflow.com/questions/3488691/how-to-rotate-a-matrix-90-degrees-without-using-any-extra-space
    raise "Matrix Not Square" unless getRowSize == getColSize
    if val == 0
      n = self.getColSize
      f = (self.getColSize/2).floor
      c = (self.getRowSize/2).ceil
      a = self.clone
      (0..f-1).each{|x|
        (0..c-1).each{|y|
          temp = a[x,y]
          a[x,y] = a[y,n-1-x]
          a[y,n-1-x] = a[n-1-x,n-1-y]
          a[n-1-x,n-1-y] = a[n-1-y,x]
          a[n-1-y,x] = temp
        }
      }
      return a
      elsif val == 1
        return self.clone.rotate(0).rotate(0)
      elsif val == 2
        return self.clone.rotate(0).rotate(0).rotate(0)
    else
      raise "val is 0,1,2 for 90,180,270 degree rotation"
    end
  end

  def rank #adapted from http://www.ruby-doc.org/stdlib-1.9.3/libdoc/matrix/rdoc/Matrix.html#method-i-rank
    a = self.clone
    last_column = self.getColSize - 1
    last_row = self.getRowSize - 1
    pivot_row = 0
    previous_pivot = 1
    0.upto(last_column) do |k|
      switch_row = (pivot_row .. last_row).find {|row|
        a[row][k] != 0
      }
      if switch_row
        a.rowSwitch(switch_row,pivot_row,0) unless pivot_row == switch_row
        pivot = a[pivot_row][k]
        (pivot_row+1).upto(last_row) do |i|
          ai = a.row(i)
          (k+1).upto(last_column) do |j|
            ai[j] =  (pivot * ai[j] - ai[k] * a[pivot_row][j]) / previous_pivot
          end
        end
        pivot_row += 1
        previous_pivot = pivot
      end
    end
    return pivot_row
  end

  def rowOper(index1,index2, symbol)
    dup = self.clone
    row = dup.row(index1)
    (0..dup.getColSize-1).each{|i|
      dup[index1][i] = dup[index1][i].send(symbol, dup[index2][i])
    }
    return dup
  end

  def inv
    result = SparseMatrix.create(self.getRowSize,self.getColSize)
    (0..getRowSize-1).each{|i|
      (0..getColSize-1).each{|j|
        dup = self.clone
        dup = dup.subMatrix([i],[j])
        sum = i + j
        result[i][j] = (((-1.0)**(sum)) * dup.det)
      }
    }
    result = result.transpose
    result = result*((1.0/self.det))
    result.each_with_index { |index,value | result.put(index,value.round(10))}
    return result
  end

  end
