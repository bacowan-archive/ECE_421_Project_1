class AbstractDataStructure

  def getRowSize
    raise NotImplementedError
  end

  def getColSize
    raise NotImplementedError
  end

  def rowCount
    raise NotImplementedError
  end

  def transpose
    raise NotImplementedError
  end

  def put
    raise NotImplementedError
  end

  def each
    raise NotImplementedError
  end

  def each_with_index
    raise NotImplementedError
  end

  def []
    raise NotImplementedError
  end

  def +(other)
    raise NotImplementedError
  end

  def toBaseMatrix
    raise NotImplementedError
  end
end