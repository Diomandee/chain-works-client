(use-trait Ft-trait .sip010-ft-trait.sip010-ft-trait)
(use-trait chain-usda-trait .chain-usda-trait.chain-usda-trait)

(define-constant CONTRACT_OWNER tx-sender)
(define-constant Chain_Stream .chain-stream)
(define-constant PARENT_ID (get-or-create-parent-id tx-sender))

;; error codes

(define-public (is-dao-or-extension)
	(ok (asserts! (or (is-eq tx-sender .chain-dao) (contract-call? .chain-dao is-extension contract-caller)) ERR_UNAUTHORIZED))
)
(define-constant ONE_8 u1) 
(define-constant ONE_10 u100000000000) 
(define-constant ERR_UNKNOWN_PARENT (err u123123))
(define-constant ERR_UNAUTHORIZED (err u401))
(define-constant ERR_STREAM_NOT_FOUND (err u404))
(define-constant ERR_WITHDRAW_GREATER_BALANCE (err u405))
(define-constant ERR_BALANCE_GREATER_DEPOSIT (err u406))
(define-constant ERR_TIMEOUT_IN_PAST (err u407))
(define-constant ERR_DEPOSIT_SMALLER_DELTA (err u412))
(define-constant ERR_DEPOSIT_NOT_MULTIPLE_DELTA (err u413))
(define-constant ERR_RECIPIENT_GREATER_BALANCE (err u411))
(define-constant ERR_AMOUNT_IS_ZERO (err u414))
(define-constant ERR_AMOUNT_EXCEEDS_BALANCE (err u415))
(define-constant ERR_NOT_RECIPENT_OR_SENDER (err u400))
(define-constant ERR_STREAM_NOT_EXIST (err u401))
(define-constant REMOVE_DEPOSIT_FAIL (err u421))
(define-constant NOT_OWNER (err u421))
(define-constant NOT_CHILD (err u422))
(define-constant DEFAULT_PORTION u100)
(define-constant ERR_NOT_PAYMENT_TOKEN (err u420))
(define-constant ERR_TOO_MANY_POOLS (err u2004))
(define-constant  ERR-NOT-AUTHORIZED u1403001)
(define-data-var last-chain-id uint u0)
(define-constant ERR-TOO-MANY-POOLS (err u2004))

(define-non-fungible-token chain-child {token-id: uint, parent-id: uint})

;; data maps and vars

(define-map CreateStreamLocalVars uint { duration: uint, ratePerSecond: uint})
;; (define-map benificary uint (list 100 {portions: uint, recipient: principal} ))
(define-map owner-collateral {owner: principal} { stream-id: uint, collateral: uint})
(define-map benificary uint (list 200 principal))
(define-map host uint (list 200 principal))


(define-data-var next-stream-id uint u1)
(define-data-var total-collateral uint u0) 
(define-data-var user-count uint u0)
(define-data-var parent-count uint u0)


(define-map Stream uint {
  sender: principal,  
  recipient: principal,       
  deposit: uint,
  token-address: principal,
  start-time: uint,
  closing-time: uint,
  is-active: bool,
  remaining-balance: uint,  
  rate-per-seconds: uint,
  portions: uint,
  parent-id: uint
})

(define-map balance-of-chain {id: uint} {
    id: uint,
    recipient-balance: uint,
    withdrawal-amount: uint,
    sender-balance: uint,
    updated-at-block-height: uint
})

(define-map collateral-withdrawn uint uint)

(define-map total-value {stream-id: uint} 
{
  owner: principal,
  total-recipents: uint,
  collateral: uint,
})

(define-map user-ids {users: principal} uint)
(define-map user-id-by-address principal uint)
(define-map user-by-id uint { user: principal})

(define-map parent-id-by-address principal uint)
(define-map parent-by-id uint { parent: principal})
(define-map parent-ids {parents: principal} uint)


(define-map Chains uint {
  chain-id: uint,
  owner: principal, 
  totalValue: uint,
  portions: uint,
  recipients: (list 200 principal),
  co-host: (optional (list 200 principal)),
})

(define-map chain-entries { user: principal } { ids: (list 20 uint) })

(define-map closing-chain
  { user: principal }
  { chain-id: uint }
)

(define-map Meta uint
  {
  owner: principal,
  chain-id: uint,
  listed: bool,
  price: uint
})

(define-map Chain uint {
  chain-id: uint,
  owner: principal, 
  recipient: principal, 
  portions: uint,
  recipients: (list 100 {recipient: principal}),
})

(define-map chains { id: uint } {
  id: uint,
  owner: principal,
  collateral: uint,
  collateral-type: (string-ascii 12),
  collateral-token: (string-ascii 12),
  debt: uint,
  created-at-block-height: uint,
  updated-at-block-height: uint,
  is-liquidated: bool,
  is-minted: bool,
  leftover-collateral: uint
})

(define-map Child {stream-id: uint, parent-id: uint} 
  { 
      stream-id: uint,
      parent-id: uint, 
      child-id:  uint, 
      parent: principal,
      child: principal,
      portions: uint,
      child-count: uint,
      is-active: bool,
  }
)

(define-map Parents {parent-id: uint} 
  { 
    parent-id: uint,
    owner: principal, 
    recipient: principal, 
    recipients: (list 100 {portions: uint, recipient: principal}),
    count: uint,
    portions:  uint,
    deposit: uint,
    closing-time: uint,
    start-time: uint,
  }
)

(define-read-only (get-child (stream-id uint) (parent-id uint))
 (ok (default-to
    { 
    stream-id:  u0,
    parent-id: u0,
    child-id:  u0,
    parent: .chain-manager, 
    portions:  u0,
    child-count: u0,
    is-active: false,
    }
   (map-get? Child {stream-id: stream-id, parent-id: parent-id}))
  )
)

(define-read-only (get-local-balance (stream-id uint))
 (ok (default-to
  { 
    id: u0,
    recipient-balance: u0,
    withdrawal-amount: u0,
    sender-balance: u0,
    updated-at-block-height: u0
  }
   (map-get? balance-of-chain  {id: stream-id}))))

(define-read-only (get-parent (parent-id uint) )
  (ok (default-to
    { 
    parent-id: u0,
    owner: tx-sender,
    portions:  u0,
    recipient: tx-sender,
    recipients: (list ),
    count: u0,
    closing-time: block-height,
    deposit: u0,
    start-time: u0
    }
   (map-get? Parents {parent-id: parent-id} ))
  )
)

(define-read-only (get-chain-by-id (id uint))
  (default-to
    {
      id: id,
      owner: CONTRACT_OWNER,
      collateral: u0,
      collateral-type: "STX",
      collateral-token: "STX",
      debt: u0,
      created-at-block-height: u0,
      updated-at-block-height: u0,
      is-liquidated: false,
      is-minted: false,
      leftover-collateral: u0
    }
    (map-get? chains { id: id })
  )
)

(define-read-only (get-meta (chain-id uint))
  (map-get? Meta chain-id)
)


(define-read-only (get-chain (chain-id uint))
  (map-get? Chains chain-id)
)
;; ---------------------------------------------------------
;; Chain Functions 
;; ---------------------------------------------------------


(define-public (change-chain (recipient principal)) 
   (let (
    (chain-id (get-or-create-parent-id tx-sender))
     ) 
      (change-chain-internal chain-id recipient))
)

(define-public (update-recipient  (recipient principal)) 
   (let (
    (chain-id (get-or-create-parent-id tx-sender))
     ) 
      (update-recipient-internal chain-id recipient))
)

(define-public (add-recipient (recipient principal))
  (let (
    (chain-id (get-or-create-parent-id tx-sender))
  ) 
    (add-recipient-internal chain-id recipient)
  )
)

(define-public (remove-recipient (recipient principal))
  (let (
    (chain-id (get-or-create-parent-id tx-sender))
  ) 
    (remove-recipient-internal chain-id recipient)
  )
)


(define-private (get-recipients (chain-id uint) (recipient principal)) 
  (ok 
    (unwrap! (as-max-len? (append (get-benificary chain-id ) recipient) u200) ERR-TOO-MANY-POOLS)
  )
)

(define-read-only (get-host (chain-id uint))
    (default-to (list) (map-get? host chain-id ))
)


(define-private (get-hosts (chain-id uint) (recipient principal)) 
  (ok 
    (unwrap! (as-max-len? (append (get-host chain-id ) recipient) u200) ERR-TOO-MANY-POOLS)
  )
)

(define-read-only (get-benificary (chain-id uint))
    (default-to (list) (map-get? benificary chain-id ))
)

(define-public (update-owner (recipient principal)) 
   (let (
    (chain-id (get-or-create-parent-id tx-sender))
     ) 
      (update-owner-internal chain-id recipient))
)

(define-public (add-host (id uint) (recipient principal))
  (let (
    (chain-id (get-or-create-parent-id tx-sender))
  ) 
    (add-host-internal id recipient)
  )
)
(define-private (update-owner-internal (chain-id uint) (new-owner principal)) 
  (begin 
    (let (
    (chain (unwrap-panic (map-get? Chains chain-id)))
    (id (get chain-id chain))
    (data (unwrap-panic (get-meta id)))
    )
      (map-set Meta chain-id (merge data {owner: new-owner }))
      (map-set Chains chain-id (merge chain {chain-id: chain-id, owner: new-owner}))

      (ok true)
    )
  )
)

(define-private (change-chain-internal (chain-id uint) (new-owner principal)) 
  (begin 
    (let (
      (chain (unwrap-panic (map-get? Chains chain-id)))
      (id (get chain-id chain))
      (data (unwrap-panic (get-meta id)))
      (recipients (unwrap-panic (get-recipients id new-owner)))
    )
      ;; (try! (contract-call? .cwe000-chain-usda tag-nft-token-id-transfer new-owner {chain-id: chain-id, owner: tx-sender}))
    (map-set Chains chain-id (merge chain { chain-id: chain-id , owner: new-owner }))
      (map-set Meta (var-get last-chain-id) (merge data {owner: new-owner}))
      (unwrap-panic (update-owner-internal chain-id new-owner))
      (ok true)
    )
  )
)

(define-private (add-host-internal (chain-id uint) (new-owner principal)) 
  (begin 
    (let (
    (chain (unwrap-panic (map-get? Chains chain-id)))
    (id (get chain-id chain))
    (data (unwrap-panic (get-meta id)))
    (hosts (unwrap-panic (get-hosts chain-id new-owner))))
    
    (map-set Meta chain-id (merge data {owner: new-owner }))
    (map-set Chains chain-id (merge chain {chain-id: chain-id, co-host: (some hosts)}))
      (ok true)
    )
  )
)

(define-private (update-recipient-internal (chain-id uint) (recipient principal)) 
  (begin 
    (let (
      (chain (unwrap-panic (map-get? Chains chain-id)))
      (id (get chain-id chain))
      (recipients (unwrap-panic (get-recipients chain-id recipient)))
    )
    (map-set Chains chain-id (merge chain { recipients: recipients}))
      (ok true)
    )
  )
)

(define-private (add-recipient-internal (chain-id uint) (recipient principal)) 
  (begin 
    (let (
      (Owner tx-sender)
      (chain (unwrap-panic (get-chain chain-id)))
      (recipients (unwrap-panic (get-recipients chain-id recipient)))
      (lenth (len recipients))
      (val (/ DEFAULT_PORTION lenth))
      (current-total-collateral (var-get total-collateral))
    )
      (map-set benificary chain-id recipients)
      (map-set Chains chain-id (merge chain {chain-id: chain-id, portions: val,recipients: recipients, totalValue: current-total-collateral}))
    )	
   (ok true)
  )
)

(define-private (remove-recipient-internal (chain-id uint) (recipient principal)) 
  (begin 
    (let (
      (Owner tx-sender)
      (chain (unwrap-panic (get-chain chain-id)))
      (recipients (unwrap-panic (get-recipients chain-id recipient)))
      (deleteRecipients (filter remove-recipent-filter recipients))
    )
      (map-set benificary chain-id deleteRecipients)
      (map-set Chains chain-id (merge chain {chain-id: chain-id, recipients: deleteRecipients}))
    )	
   (ok true)
  )
)

(define-private (remove-recipent-filter (recipient principal))
  (not (is-eq recipient))
)

(define-public (create-parent 
(owner principal) 
(recipients (list 100 {portions: uint, recipient: principal}))
(deposit uint) 
(closing-time uint))
  (begin
    (map-set Parents  {parent-id: PARENT_ID}
    {
      owner: owner,
      parent-id: PARENT_ID, 
      recipients: recipients,
      recipient: .chain-manager,
      deposit: deposit, 
      count: (len recipients), 
      closing-time: closing-time,
      portions: (/ DEFAULT_PORTION (len recipients)),
      start-time: block-height
    }
  )
  
    (unwrap-panic (create-chain recipients))
    (ok true)
  )
)

;; Withdraw Functions
(define-public (withdraw-transfer (amount uint) (recipient principal))
  (ok 
    (withdraw-stream 
    (get-or-create-user-id (get recipient (my-stream)))
    (get parent-id (my-stream))
    amount 
    recipient
    )
  )
)

(define-public (withdraw-transfer-all (recipient principal))
  (ok
    (withdraw-stream
    (get-or-create-user-id (get recipient (my-stream)))
    (get parent-id (my-stream))
    (get remaining-balance (my-stream))
    recipient
    )
  )
)

(define-public (withdraw (amount uint))
  (ok
    (withdraw-stream 
    (get-or-create-user-id (get recipient (my-stream)))
    (get parent-id (my-stream)) 
    amount 
    tx-sender)
  )
)

(define-public (withdraw-all)
  (ok
    (withdraw-stream
    (get-or-create-user-id (get recipient (my-stream)))
    (get parent-id (my-stream))
    (get remaining-balance (my-stream)) 
    tx-sender)
  )
)

(define-private (withdraw-stream (stream-id uint) (parent-id uint) (amount uint) (owner principal)) 
  (let (
    (stream (unwrap! (get-stream stream-id) ERR_STREAM_NOT_FOUND))
    (delta (unwrap-panic (delta-of stream-id)))
    (dynamic (unwrap-panic (get-local-balance stream-id)))
    (current-withdrawn  (withdrawn stream-id))
    (new-amount-withdrawn (+ amount current-withdrawn))    
    (recipient-balance (get recipient-balance dynamic))
    (new-recipient-balance (- recipient-balance new-amount-withdrawn)) 
    (remaining-balance (- (get remaining-balance stream) amount ))
    (sender-balance (get sender-balance dynamic))
  )
    (asserts! (unwrap-panic (stream-exist stream-id )) ERR_STREAM_NOT_EXIST)
    (asserts! (not (is-eq (is-owner owner) true)) ERR_STREAM_NOT_EXIST)
    (asserts! (> amount u0) ERR_AMOUNT_IS_ZERO)
    (asserts! (> recipient-balance amount) ERR_AMOUNT_EXCEEDS_BALANCE)
    (asserts! (unwrap! (is-sender-or-recipient stream-id) ERR_NOT_RECIPENT_OR_SENDER) ERR_NOT_RECIPENT_OR_SENDER)
    (asserts! (not (is-eq remaining-balance u0)) (ok (map-delete Stream stream-id)))
    (asserts! (> (- remaining-balance amount) sender-balance) ERR_AMOUNT_EXCEEDS_BALANCE)

  (begin
    (map-set Stream stream-id (merge stream {remaining-balance: remaining-balance })) 
    (map-set collateral-withdrawn stream-id new-amount-withdrawn) 
    (map-set balance-of-chain {id: stream-id} 
    (merge dynamic { withdrawal-amount: new-recipient-balance}))
    (unwrap! (remove-deposit amount owner) REMOVE_DEPOSIT_FAIL)     
    (unwrap-panic (balance-of stream-id Chain_Stream))
  )
    (ok true)
  )
)

(define-private (remove-deposit (deposit uint) (owner principal))
  (let (
    (current-collateral (get-collateral-amount-of owner))
    (id (get-stream-id-of owner))
    (current-total-value (get-total-value-amount-of id))
    (current-total-recipents (get-total-recipents-of id))
    (new-collateral-owner (- current-collateral deposit))
    (new-collateral-chain (- current-total-value deposit))
  )
    (map-set owner-collateral { owner: owner } 
      { 
        collateral: new-collateral-owner, 
        stream-id: id 
      }
    ) 
    (map-set total-value {stream-id: id } 
      { 
        collateral: new-collateral-chain, 
        total-recipents: current-total-recipents, 
        owner: .chain-stream 
      }
    )
(let (
      (chain { id: id, owner: owner, collateral: new-collateral-chain, collateral-type: "STX", collateral-token: "STX", debt: u0, created-at-block-height: block-height, updated-at-block-height: block-height, is-liquidated: false, is-minted: false, leftover-collateral: u0 })
    )
      (unwrap-panic (update-chain id chain))

    (try! (contract-call? .cwe000-chain-usda transfer id deposit tx-sender owner))
      (print { type: "vault", chain: "created", data: chain })
      (ok chain)
    )
  ) 
)


(define-public (balance-of (stream-id uint) (who principal))
  (let (
    (stream (unwrap! (get-stream stream-id) ERR_STREAM_NOT_FOUND))
    (remaining-balance (get remaining-balance stream))
    (delta (unwrap-panic (delta-of stream-id)))
    (current-withdrawn  (withdrawn stream-id))
    (recipient-balance (mul-up delta (get rate-per-seconds stream)))
    (new-recipient-balance (- recipient-balance current-withdrawn ))
    (sender-balance (- remaining-balance recipient-balance))
    (bal 
      {
        id: stream-id, 
        recipient-balance: recipient-balance, 
        sender-balance: sender-balance, 
        withdrawal-amount:  new-recipient-balance, 
        updated-at-block-height:
        block-height 
      }
    )
  )
  (begin 
  (try! (is-dao-or-extension))

    (map-set balance-of-chain (tuple (id stream-id)) bal)
      (or 
        (asserts! (>= (get deposit stream) remaining-balance) ERR_BALANCE_GREATER_DEPOSIT)
        (asserts! (is-eq who (get recipient stream)) (ok sender-balance))
        (asserts! (is-eq who (get sender stream)) (ok recipient-balance))
        (asserts! (is-eq who Chain_Stream) (ok recipient-balance))
      )
    (print {balance: bal})
  )
    (ok u0)
  )
)

(define-private (create-chain (recipients (list 100 {portions: uint, recipient: principal})))
  (ok 
    (begin 
      (map create-chain-internal recipients)
      (unwrap-panic (contract-call? .cwe000-chain-usda mint (get deposit (my-parent)) (get parent-id (my-parent)) (get owner (my-parent))))
      (try! (contract-call? .cwe000-chain-usda transfer PARENT_ID (get deposit (my-parent)) tx-sender .chain-manager))
    )
  )
)


(define-private (create-chain-internal (item {portions: uint, recipient: principal}))
  (let (
    (user-id (get-or-create-parent-id tx-sender))
    (child-id (get-or-create-user-id (get recipient item )))
    (stream-id (var-get next-stream-id))
    (parent (unwrap! (get-parent user-id) ERR_UNKNOWN_PARENT))
    (parent-id (get parent-id parent))
    (closing-time (get closing-time parent))
    (duration (sub-up closing-time block-height))
    (rate-per-seconds (div-up duration (get deposit parent)))
    ;; (items (unwrap-panic (get-items parent-id (get portions item) (get recipient item))))
  )
    (asserts! (> closing-time block-height) ERR_TIMEOUT_IN_PAST)
    (asserts! (> (get deposit parent) u0) ERR_AMOUNT_IS_ZERO)
  (begin 
    (var-set next-stream-id (+ stream-id u1))
    (map-set user-id-by-address (get recipient item ) child-id)
    (try! (nft-mint? chain-child {token-id: child-id, parent-id: parent-id} (get recipient item )))
    ;; (map-set benificary parent-id items)

    (map-set CreateStreamLocalVars child-id 
      {
        duration: duration,
        ratePerSecond: (* rate-per-seconds u100000000)
      }
    )

   (map-set Child { stream-id: child-id, parent-id: parent-id}
     {
      stream-id: stream-id,
      parent-id: parent-id, 
      child-id:  child-id, 
      parent: tx-sender,
      child: (get recipient item),
      portions: (get portions item),
      child-count: u0,
      is-active: true, 
     }
    )
 
    (map-set Stream child-id 
      { 
        parent-id: parent-id,
        sender: tx-sender, 
        start-time: block-height,
        closing-time: closing-time, 
        remaining-balance: (/  (/ (* (get portions item ) ONE_10)  (get deposit parent))) , 
        deposit: (/ (* (get portions item ) ONE_10)  (get deposit parent)), 
        portions: (get portions item), 
        recipient: (get recipient item), 
        is-active: true, 
        token-address: .cwe000-chain-usda, 
        rate-per-seconds: (div-up (div-up (* (get portions item ) u100000) (get deposit parent) ) duration)
      }
    )
  )
    (unwrap-panic (add-deposit parent-id (get deposit parent) tx-sender (len (get recipients parent) )))
    (ok stream-id)
  )
)

(define-private (add-deposit 
(parent-id uint ) 
(collateral uint) 
(owner principal) 
(num uint))
  (let (
    (current-collateral (get-collateral-amount-of owner))
    (new-collateral (+ collateral current-collateral)) 
    (chain (get-chain-by-id parent-id))
     (updated-chain (merge chain {
      collateral: new-collateral,
      updated-at-block-height: block-height
    }))   
  )

  (asserts! (is-eq contract-caller CONTRACT_OWNER) (err ERR-NOT-AUTHORIZED))

    (map-set owner-collateral { owner: owner } 
      { 
        collateral: new-collateral, 
        stream-id: parent-id 
      }
    ) 

    (map-set total-value {stream-id: parent-id } 
      { 
        collateral: new-collateral, 
        total-recipents: num, 
        owner: .chain-stream
      }
    ) 
      (map-set chains (tuple (id parent-id)) 
      {
        id: parent-id, 
        owner: owner, 
        collateral: new-collateral, 
        collateral-type: "STX",
        collateral-token: "STX", 
        debt: (get debt chain), 
        created-at-block-height: block-height, 
        updated-at-block-height: block-height, 
        is-minted: false, 
        is-liquidated: false, 
        leftover-collateral: u0
    })

    (unwrap-panic (update-chain parent-id updated-chain))

    (ok true )
  )
)

(define-public (update-chain (chain-id uint) (data (tuple (id uint) (owner principal)  (collateral uint)  (collateral-type (string-ascii 12))  (collateral-token (string-ascii 12))  (debt uint) (is-minted bool) (created-at-block-height uint)  (updated-at-block-height uint)  (is-liquidated bool)  (leftover-collateral uint))))
  (let (
    (chain (get-chain-by-id chain-id)))
    (asserts! (is-eq contract-caller CONTRACT_OWNER) (err ERR-NOT-AUTHORIZED))
    (map-set chains (tuple (id chain-id)) data)
    (ok chain)
  )
)



(define-read-only (delta-of (parent-id uint)) 
  (let (
    (parent (unwrap! (get-parent parent-id) ERR_STREAM_NOT_FOUND))
    (startTime (get start-time parent))
    (closing-time (get closing-time parent))
    (timeStamp (default-to block-height (get-block-info? time block-height )))
  )
    (begin 
      ;; (asserts! (is-eq stream-exis true) ERR_STREAM_NOT_EXIST)
      (asserts! (>= timeStamp startTime ) (ok u0))
      (asserts! (> timeStamp closing-time ) (ok (- timeStamp startTime)))
      (ok (- closing-time startTime))
    )
  )
) 


(define-read-only (get-collateral-amount-of (owner principal))
  (get collateral (get-collateral-of owner))
)

(define-read-only (get-stream-id-of (owner principal))
  (get stream-id (get-collateral-of owner))
)

(define-read-only (get-collateral-of (owner principal))
  (default-to
    { collateral: u0, stream-id: u0}
    (map-get? owner-collateral { owner: owner })
  )
)

(define-read-only (withdrawn (stream-id uint))
  (default-to
    u0
    (map-get? collateral-withdrawn stream-id )
  )
)

(define-read-only (get-total-value-of (stream-id uint))
  (default-to
    { collateral: u0, total-recipents: u0}
    (map-get? total-value  {stream-id: stream-id })
  )
)

(define-read-only (get-total-value-amount-of (stream-id uint))
  (get collateral (get-total-value-of stream-id ))
)

(define-read-only (chain-nonce)
  (ok (var-get next-stream-id))
)

(define-read-only (get-total-recipents-of (stream-id uint))
  (get total-recipents (get-total-value-of stream-id ))
)

(define-read-only (create-stream-local-info (stream-id uint)) 
    (map-get? CreateStreamLocalVars stream-id)
)

(define-read-only (get-stream (stream-id uint))
  (map-get? Stream stream-id)
)

(define-read-only (stream-exist (stream-id uint)) 
  (ok 
    (asserts! (is-some (get-stream stream-id)) ERR_STREAM_NOT_FOUND)
  )
)
;; Math functions

(define-read-only (sub-up (a uint) (b uint)) 
  (let ((subtract (- a b))) (if (<= subtract u0) u0 subtract))
)

(define-read-only (div-up (a uint) (b uint)) 
  (if (is-eq a u0) u0 (+ u1 (/ (- (* a ONE_8) u1) b)))
)

(define-read-only (mul-up (a uint) (b uint))
  (let ((product (* a b))) (if (is-eq product u0)  u0 (+ u1 (/ (- product u1) ONE_8))))
)

;; Private functions
(define-private (get-or-create-parent-id (parent principal))
  (match
    (map-get? parent-ids {parents: parent})
    value value
    (let (
      (parent-count-id (unwrap-panic
      (contract-call? .cwe000-chain-usda get-or-create-asset-token-id parent))))
      (map-insert parent-ids {parents: parent} parent-count-id )
      (var-set parent-count parent-count-id)
      (map-set parent-id-by-address parent parent-count-id)
      (map-set parent-by-id parent-count-id { parent: tx-sender})
      parent-count-id
    )
  )
)

(define-private (get-or-create-user-id (user principal))
  (match
    (map-get? user-ids {users: user})
    value value
    (let (
      (user-count-id (+ u1 (var-get user-count)))
      )
      (map-insert user-ids {users: user} user-count-id)
      (var-set user-count user-count-id)
      (map-set user-id-by-address user user-count-id)
      (map-set user-by-id user-count-id { user: tx-sender})
      user-count-id
    )
  )
)

(define-private (is-owner (owner principal))
  (let (
    (parent-id (get parent-id (my-stream)))
  ) 
  (and 
    (is-eq (unwrap! (nft-get-owner? chain-child {token-id: (get-or-create-user-id owner), parent-id: parent-id}) false)
    tx-sender)
    (is-some (nft-get-owner? chain-child {token-id: (get-or-create-user-id owner), parent-id: parent-id}))
  )) 
)


(define-private (remove-burned-chain (chain-id uint))
  (let ((current-chain (unwrap-panic (map-get? closing-chain { user: tx-sender }))))
    (if (is-eq chain-id (get chain-id current-chain))
      false
      true
    )
  )
)

(define-read-only (get-chains (user principal))
  (let ((entries (get ids (get-chain-entries user))))
    (ok (map get-chain-by-id entries))
  )
)

(define-read-only (get-chain-entries (user principal))
  (unwrap! (map-get? chain-entries { user: user }) (tuple (ids (list u0) )))
)

(define-public (close-chain (chain-id uint))
  (let (
    (chain (get-chain-by-id chain-id))
    (entries (get ids (get-chain-entries (get owner chain))))
  )
     (asserts! (is-eq contract-caller CONTRACT_OWNER) (err ERR-NOT-AUTHORIZED)
    )

    (map-set closing-chain { user: (get owner chain) } { chain-id: chain-id })
    (map-set chain-entries { user: tx-sender } { ids: (filter remove-burned-chain entries) })
    (ok (map-delete chains { id: chain-id }))
  )
)

(define-private (is-sender (stream-id uint))
  (is-eq (some tx-sender) (get sender (get-stream stream-id)))
)

(define-private (my-stream) 
 (unwrap-panic (get-stream (get-or-create-user-id tx-sender)))
)

(define-private (my-parent) 
 (unwrap-panic (get-parent (get-or-create-parent-id tx-sender)))
)

(define-private (is-sender-or-recipient (stream-id uint)) 
  (ok
    (asserts! (or (is-eq tx-sender (get sender (my-stream))) (is-eq tx-sender (get recipient (my-stream)))) ERR_UNAUTHORIZED)
  )
)

;; (define-private (get-items (stream-id uint) (portions uint) (recipient principal)) 
;;   (ok 
;;     (unwrap! (as-max-len? (append (get-benificary stream-id ) {portions: portions, recipient: recipient}) u100) ERR_TOO_MANY_POOLS)
;;   )
;; )






    (begin (unwrap-panic (create-parent  tx-sender
  
        (list
        {portions: u10, recipient: 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5}
        {portions: u10, recipient: 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG}
        {portions: u10, recipient: 'ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC}
        {portions: u10, recipient: 'ST2NEB84ASENDXKYGJPQW86YXQCEFEX2ZQPG87ND}
        {portions: u10, recipient: 'ST2REHHS5J3CERCRBEPMGH7921Q6PYKAADT7JP2VB}
        ;; {portions: u10, recipient: 'ST3AM1A56AK2C1XAFJ4115ZSV26EB49BVQ10MGCS0}
        ;; {portions: u10, recipient: 'ST3NBRSFKX28FQ2ZJ1MAKX58HKHSDGNV5N7R21XCP}
        ;; {portions: u10, recipient: 'ST3PF13W7Z0RRM42A8VZRVFQ75SV1K26RXEP8YGKJ}
        ;; {portions: u20, recipient: 'STNHKEPYEPJ8ET55ZZ0M5A34J0R3N5FM2CMMMAZ6}
        
        )

      u1000000000
      u2000
         )

         
         )

      )
    