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
end