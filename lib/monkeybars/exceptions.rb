module Monkeybars
  class UndefinedControlError < RuntimeError; end
  class InvalidSignalHandlerError < RuntimeError; end
  class UndefinedSignalError < RuntimeError; end
  class InvalidCloseAction < RuntimeError; end
  class InvalidMappingError < RuntimeError; end
  class TranslationError < RuntimeError; end
  class InvalidNestingError < RuntimeError; end
  class InvalidHandlerError < RuntimeError; end
end