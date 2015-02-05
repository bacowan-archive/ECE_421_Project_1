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
        (0..@rows).each {|i| @map[i] = Hash.new(0) }
      else
        raise "matrices of dimensions other than 2 are not currently supported"
      end
    elsif args.size == 1
      _copyMatrix(args[0])
    else
      raise "invalid initialization arguments"
    end

  end

  # Copy the input matrix into this matrix
  def _copyMatrix(matrix)

    @rows = matrix.row_size
    @columns = matrix.column_size

    # create an entry for each row, and default the values to 0
    (0..@rows).each {|i| @map[i] = Hash.new(0) }

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
    raise "index has the wrong number of values" unless dims == 2
    raise "index is out of bounds" unless dupIndex[0] >= 0 and dupIndex[0] < @rows and dupIndex[1] >= 0 and dupIndex[1] < @columns

    # note: from http://stackoverflow.com/questions/14294751/how-to-set-nested-hash-in-ruby-dynamically
    # TODO: make the getter functions in a similar fashion
    last = dupIndex.pop
    dupIndex.inject(@map, :fetch)[last] = val

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
    if index.kind_of?(Array)
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

end