require 'economic/proxies/entity_proxy'

module Economic
  class DebtorProxy < EntityProxy
    # Returns Debtors that have the given ci_number. The Debtor objects will only be partially loaded
    def find_by_ci_number(ci_number)
      # Get a list of DebtorHandles from e-conomic
      response = session.request entity_class.soap_action('FindByCINumber') do
        soap.body = {
          'ciNumber' => ci_number
        }
      end

      # Make sure we always have an array of handles even if the result only contains one
      handles = [response[:debtor_handle]].flatten.reject(&:blank?)

      # Create partial Debtor entities
      handles.collect do |handle|
        debtor = build
        debtor.partial = true
        debtor.persisted = true
        debtor.handle = handle
        debtor.number = handle[:number]
        debtor
      end
    end

    # Returns the next available debtor number
    def next_available_number
      session.request Debtor.soap_action(:get_next_available_number)
    end
  end
end