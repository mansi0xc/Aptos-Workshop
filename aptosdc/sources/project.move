module MyModule::Procurement {
    use aptos_framework::signer;
    use std::error;
    use aptos_framework::account;
    
    /// Error codes
    const E_NOT_AUTHORIZED: u64 = 1;
    const E_REQUEST_NOT_FOUND: u64 = 2;
    const E_ALREADY_APPROVED: u64 = 3;
    
    /// Procurement request status
    const STATUS_PENDING: u8 = 0;
    const STATUS_APPROVED: u8 = 1;
    
    /// Struct representing a procurement request
    struct ProcurementRequest has store, key {
        id: u64,
        amount: u64,
        description: vector<u8>,
        status: u8,
        requester: address
    }
    
    /// Resource to track the approver role
    struct ApproverRole has key {}
    
    /// Resource to store the next request ID
    struct RequestCounter has key {
        next_id: u64
    }
    
    /// Initialize the module (called once by the admin)
    public fun initialize(admin: &signer) {
        move_to(admin, RequestCounter { next_id: 1 });
    }
    
    /// Assign approver role to an account
    public fun assign_approver_role(admin: &signer, approver_address: address) {
        let admin_addr = signer::address_of(admin);
        assert!(admin_addr == @MyModule, error::permission_denied(E_NOT_AUTHORIZED));
        
        let approver_signer = account::create_signer_with_capability(
            &account::create_test_signer_cap(approver_address)
        );
        move_to(&approver_signer, ApproverRole {});
    }
    
    /// Create a new procurement request
    public fun create_request(requester: &signer, amount: u64, description: vector<u8>) acquires RequestCounter {
        let requester_addr = signer::address_of(requester);
        let counter = borrow_global_mut<RequestCounter>(@MyModule);
        
        let request = ProcurementRequest {
            id: counter.next_id,
            amount,
            description,
            status: STATUS_PENDING,
            requester: requester_addr
        };
        
        counter.next_id = counter.next_id + 1;
        move_to(requester, request);
    }
    
    /// Approve a procurement request
    public fun approve_request(approver: &signer, requester_addr: address, request_id: u64) acquires ProcurementRequest {
        let approver_addr = signer::address_of(approver);
        
        // Check that approver has the proper role
        assert!(exists<ApproverRole>(approver_addr), error::permission_denied(E_NOT_AUTHORIZED));
        
        // Check that the request exists
        assert!(exists<ProcurementRequest>(requester_addr), error::not_found(E_REQUEST_NOT_FOUND));
        
        let request = borrow_global_mut<ProcurementRequest>(requester_addr);
        assert!(request.id == request_id, error::not_found(E_REQUEST_NOT_FOUND));
        assert!(request.status == STATUS_PENDING, error::invalid_state(E_ALREADY_APPROVED));
        
        // Update the request status to approved
        request.status = STATUS_APPROVED;
    }
}