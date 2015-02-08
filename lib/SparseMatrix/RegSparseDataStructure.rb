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
    raise "index has the wrong number of values (#{dims} instead of 2)" unless dims == 2
    raise "index #{dupIndex} is out of bounds" unless dupIndex[0] >= 0 and dupIndex[0] < @rows and dupIndex[1] >= 0 and dupIndex[1] < @columns

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
    _map_iterate(@map,[],&block)
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

end