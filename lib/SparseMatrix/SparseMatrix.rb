# Base class for the sparse matrix. This class is mostly
# used as a framework to delegate functionality to its inner
# representations, that is, AbstractDataStructure.
#
# Author:: Brendan Cowan

require_relative "AbstractDataStructure"

class SparseMatrix

  # Constructor. Takes a delegate internal structure for
  # assigning its methods to
  # +delegate+:: AbstractDataStructure to assign delegation to
  def initialize(delegate)
    raise "Not a proper delegate" unless delegate.is_a? AbstractDataStructure
    @delegate = delegate
  end

end