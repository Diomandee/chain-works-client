(use-trait chain-pool-trait .chain-pool-trait.chain-pool-trait)
(use-trait collateral-types-trait .collateral-types-trait.collateral-types-trait)

(define-constant CONTRACT_OWNER tx-sender)

;; Errors
(define-constant ERR-NOT-AUTHORIZED u32401)
(define-constant ERR-UNSTAKE-AMOUNT-EXCEEDED u32002)
(define-constant ERR-WITHDRAWAL-AMOUNT-EXCEEDED u32003)
(define-constant ERR-EMERGENCY-SHUTDOWN-ACTIVATED u32004)
(define-constant ERR-STAKE-NOT-UNLOCKED u32005)
(define-constant ERR-TOO-MANY-POOLS (err u2004))
(define-constant AMOUNT_ZERO u410)
(define-constant NOT_AUTHORIZED u410)
(define-constant ERR-LIQUIDATION-FAILED u48)
(define-constant ERR-VAULT-LIQUIDATED u413)
(define-constant ERR-DEPOSIT-FAILED u45)
(define-constant ERR-INSUFFICIENT-COLLATERAL u49)
(define-constant ERR-MAXIMUM-DEBT-REACHED u410)
(define-constant ERR_DEPOSITED_ALREADY u411)
(define-constant DEFAULT_PORTION u100)
(define-constant ERR_BAD_REQUEST (err u400))
(define-constant ERR_UNAUTHORIZED (err u401))
(define-constant ERR_FORBIDDEN (err u403))
(define-constant ERR_CHALLENGE_NOT_FOUND (err u404))
(define-constant ERR_OFFER_NOT_FOUND (err u405))
(define-constant ERR_OFFER_FOR_GAME_NOT_FOUND (err u406))
(define-constant ERR_TIMEOUT_IN_PAST (err u407))
(define-constant ERR_TIMEOUT_NOT_REACHED (err u408))
(define-constant ERR_CONSENSUS_PERIOD_TIMEDOUT (err u409))
(define-constant ERR_ZERO_VALUE (err u410))
(define-constant ERR_CONTRIBUTION_NOT_STARTED (err u411))
(define-constant ERR_SHOULD_NEVER_HAPPEN (err u419))
(define-constant ERR_PENALTY_GREATER_VALUE (err u400))
(define-constant ERR_NOT_EQUAL (err u401))
(define-constant ERR_START_TIME_BEFORE (err u414))
(define-constant err-owner-only (err u100))
(define-constant err-unknown-token (err u101))
(define-constant err-cannot-be-zero (err u102))
(define-constant err-token-already-exists (err u102))
(define-constant err-insufficient-balance (err u1))
(define-constant err-invalid-sender (err u4))
(define-constant ERR-WRONG-DEBT u417)

;; Variables
(define-data-var fragments-per-token uint u1000000000000)
(define-data-var total-fragments uint u0)
(define-data-var shutdown-activated bool false)
(define-data-var lockup-blocks uint u4320)
(define-map users-nonce principal uint)
(define-data-var hatI uint u0)
(define-data-var last-chain-id uint u0)
(define-map users {token: principal, user-id: uint} principal)
(define-map Account principal {chain-id: uint, deposited: bool})
(define-map user-ids {recipients: principal} uint)
(define-map allowances {spender: principal, owner: principal} {allowance: uint})

(define-data-var total-collateral uint u0) 
(define-data-var cumm-reward-per-collateral uint u0) 
(define-data-var last-reward-increase-block uint u0) 
(define-data-var vault-rewards-shutdown-activated bool false)
(define-map benificary uint (list 200 principal))
(define-non-fungible-token chain-loan {chain-id: uint, owner: principal, 
loan: {
  id: uint,
  owner: principal,
  collateral: uint,
  collateral-type: (string-ascii 12),
  collateral-token: (string-ascii 12),
  debt: uint,
  created-at-block-height: uint,
  updated-at-block-height: uint,
  ;; stability-fee-accrued: uint,
  ;; stability-fee-last-accrued: uint,
  is-liquidated: bool,
  leftover-collateral: uint
}} )




(define-data-var freddie-shutdown-activated bool false)

(define-public (toggle-freddie-shutdown)
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) (err ERR-NOT-AUTHORIZED))

    (ok (var-set freddie-shutdown-activated (not (var-get freddie-shutdown-activated))))
  )
)

(define-public (calculate-current-collateral-to-debt-ratio-
  (token (string-ascii 12))
  (debt uint)
  (ustx uint)
)
  (let ((stx-price u1))
    (if (> debt u0)
      (ok (/ (/ (* ustx stx-price) debt) u1))
      (err u0)
    )
  )
)


;; ---------------------------------------------------------
;; Maps
;; ---------------------------------------------------------

(define-map chains { id: uint } {
  id: uint,
  owner: principal,
  collateral: uint,
  collateral-type: (string-ascii 12),
  collateral-token: (string-ascii 12),
  debt: uint,
  created-at-block-height: uint,
  updated-at-block-height: uint,
  ;; stability-fee-accrued: uint,
  ;; stability-fee-last-accrued: uint,
  is-liquidated: bool,
  is-minted: bool,
  leftover-collateral: uint
})

(define-map Chains uint {
  chain-id: uint,
  owner: principal, 
  recipient: principal, 
  portions: uint,
  recipients: (optional (list 200 principal)),
})


(define-map chain-entries { user: principal } { ids: (list 20 uint) })
(define-map closing-chain
  { user: principal }
  { chain-id: uint }
)

(define-map staker-fragments 
  { 
    staker: principal,
  } 
  {
    fragments: uint
  }
)
(define-map dynamic-balance 
  { 
    chain-id: uint,
  } 
  {
    real-time-balance: uint,
    collateral-payed: uint,
    last-accrued: uint
  }
)



(define-map meta uint
  {
  owner: principal,
  chain-id: uint,
  listed: bool,
  price: uint
})

(define-map chain-stream {id: uint}
  {
  id: uint,
  startTime: uint,
  stopTime: uint,
  interest: uint,
  ratePerSecond: uint,
  dynamic-collateral: uint,
  stability-fee-accrued: uint,
  stability-fee-last-accrued: uint
})

(define-map owner-collateral 
  {owner: principal}
    {
      chain-id: uint,
      collateral: uint,
      cumm-reward-per-collateral: uint
   }
)

(define-map staker-lockup 
  { 
    staker: principal,
  } 
  {
    start-block: uint
  }
)
(define-map challanger-lockup 
  { 
    challanger: principal,
  } 
  {
    start-block: uint,
    end-block: uint,
    cycles: uint,
    cycleLength: uint,
	  challangeDuration: uint,
    penalty: uint,
    usda: uint
  }
)
(define-map chain-reserves {id: uint} 
  {
    collateral-payed: uint
  }
)

(define-read-only (get-chain (chain-id uint))
  (map-get? Chains chain-id)
)
(define-read-only (get-chain-stream (chain-id uint))
  (map-get? chain-stream {id: chain-id})
)

(define-read-only (get-account (staker principal))
  (map-get? Account staker)
)

(define-read-only (get-account-id (staker principal))
 (get chain-id (unwrap-panic (map-get? Account staker)))
)

(define-read-only (get-staker-fragments (staker principal))
  (default-to
    { fragments: u0 }
    (map-get? staker-fragments { staker: staker })
  )
)

(define-read-only (get-staker-lockup (staker principal))
  (default-to
    { start-block: u0 }
    (map-get? staker-lockup { staker: staker })
  )
)
(define-read-only (get-challanger-lockup (challanger principal))
  (default-to
    { start-block: u0,
    end-block: u0
   }
    (map-get? challanger-lockup { challanger: challanger })
  )
)

(define-read-only (get-chain-reserves (chain-id uint))
  (default-to
    { collateral-payed: u0 }
    (map-get? chain-reserves {id: chain-id} )
  )
)
(define-read-only (get-dynamic-balance (chain-id uint))
 
    (map-get? dynamic-balance { chain-id: chain-id })
  
)

(define-read-only (get-collateral-of (owner principal))
  (default-to
    { collateral: u0, cumm-reward-per-collateral: u0, chain-id: u0}
    (map-get? owner-collateral { owner: owner })
  )
)

(define-read-only (get-stream (stream-id uint)) (contract-call? .cwe001-chain-stream get-stream stream-id))


(define-read-only (get-collateral-amount-of (owner principal))
  (get collateral (get-collateral-of owner))
)
(define-read-only (get-chain-id-of (owner principal))
  (get chain-id (get-collateral-of owner))
)
(define-read-only (get-meta (id uint))
  (map-get? meta id))

(define-read-only (get-chain-by-id (id uint))
  (default-to
    {
      id: id,
      owner: CONTRACT_OWNER,
      collateral: u0,
      collateral-type: "USDA",
      collateral-token: "USDA",
      debt: u0,
      created-at-block-height: u0,
      updated-at-block-height: u0,
      ;; stability-fee-accrued: u0,
      ;; stability-fee-last-accrued: u0,
      is-liquidated: false,
      is-minted: false,
      leftover-collateral: u0
    }
    (map-get? chains { id: id })
  )
)
(define-read-only (get-loan-by-id (id uint))
  (default-to
    {
   startTime: u0,
  stopTime: u0,
  interest: u0,
  ratePerSecond: u0,
  dynamic-collateral: u0,
  stability-fee-accrued: u0,
  stability-fee-last-accrued: u0
    }
    (map-get? chain-stream { id: id })
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

;; (define-read-only (get-chain-id-of (id uint))
;;   (get chain-id (get-meta id))
;; )
;; (define-read-only (get-owner-of (id uint))
;;   (get owner (get-meta id))
;; )
;; (define-read-only (get-shutdown-activated)
;;   (or
;;     (unwrap-panic (contract-call? .arkadiko-dao get-emergency-shutdown-activated))
;;     (var-get shutdown-activated)
;;   )
;; )

;; @desc toggles the killswitch
;; (define-public (toggle-shutdown)
;;   (begin
;;     (asserts! (is-eq tx-sender (contract-call? .arkadiko-dao get-guardian-address)) (err ERR-NOT-AUTHORIZED))

;;     (ok (var-set shutdown-activated (not (var-get shutdown-activated))))
;;   )
;; )


;; ---------------------------------------------------------
;; Getters
;; ---------------------------------------------------------

(define-read-only (get-benificary (chain-id uint))
    (default-to (list) (map-get? benificary chain-id ))
)


;; @desc get current lockup time
(define-read-only (get-lockup-blocks)
  (ok (var-get lockup-blocks))
)

;; @desc get tokens of given staker
;; @param staker; the staker to get tokens of
(define-read-only (get-tokens-of (staker principal))
  (let (
    (per-token (var-get fragments-per-token))
  )
    (if (is-eq per-token u0)
      (ok u0)
      (let (
        (user-fragments (get fragments (get-staker-fragments staker)))
      )
        (ok (/ user-fragments per-token))
      )
    )
  )
)


;; ---------------------------------------------------------
;; Deposit 
;; ---------------------------------------------------------

;; @desc stake USDA in pool
;; @param amount; amount to stake
(define-public (deposit (amount uint))
(let (
    (staker tx-sender)
    (id (+ u1 (var-get last-chain-id)))
    ;; (chain-id (get-users-nonce staker))
  )
  (begin 

    ;; (asserts! (not (get-shutdown-activated)) (err ERR-EMERGENCY-SHUTDOWN-ACTIVATED))
	  (asserts! (> amount u0) (err AMOUNT_ZERO))
    (asserts! (is-none (map-get? Account tx-sender)) (err ERR_DEPOSITED_ALREADY))
    ;; (try! (contract-call? .cwe004-chain-nft mint-nft- tx-sender))
    (map-insert Account tx-sender {chain-id: id, deposited: true} )
    (map-set staker-lockup  { staker: tx-sender } { start-block: block-height })
    (var-set last-chain-id id)
    (unwrap-panic (add-deposit amount))
    (ok amount)
)
)
)

(define-public (deposit-with-challange (amount uint) (ratio uint) (startTime uint) (days uint)) 
(let (
    (staker tx-sender)
    (id (+ u1 (var-get last-chain-id)))
    ;; (chain-id (get-users-nonce staker))
    (missedPenalty (/ amount ratio) )
    (cycles (/ amount missedPenalty))
    (cycleLength (* days u144))
    (duration (* cycles cycleLength)) 
    (timeout (+ block-height duration))
  )
  (begin 
    (asserts! (> amount u0) ERR_ZERO_VALUE) 
		(asserts! (> days u0) ERR_ZERO_VALUE)
		(asserts! (>= startTime block-height) ERR_START_TIME_BEFORE)
		(asserts! (> amount missedPenalty) ERR_PENALTY_GREATER_VALUE)
		(asserts! (> amount missedPenalty) ERR_PENALTY_GREATER_VALUE)	  (asserts! (> amount u0) (err AMOUNT_ZERO))
    (asserts! (is-none (map-get? Account tx-sender)) (err ERR_DEPOSITED_ALREADY))
    ;; (try! (contract-call? .cwe004-chain-nft mint-nft- tx-sender))
    (map-insert Account tx-sender {chain-id: id, deposited: true} )
    (map-set challanger-lockup  { challanger: tx-sender } { start-block: block-height, 
    end-block: timeout,  
    cycles: cycles,
    cycleLength: cycleLength,
	  challangeDuration: duration,
    penalty: missedPenalty,
    usda: amount
    })
    (var-set last-chain-id id)
    ;; (try! (contract-call? .cwe003-chain-challange go u"jjhhh" u"smd" amount missedPenalty startTime days))
    (unwrap-panic (add-deposit-challange amount))
    (ok amount)
)
)
)

(define-public (deposit-with-chain (amount uint) (recipients principal))
(let (
    (staker tx-sender)
    (id (+ u1 (var-get last-chain-id)))
    ;; (chain-id (get-users-nonce staker))
    (recipient (unwrap-panic (get-recipients u1 recipients)))
  )
  (begin 

    ;; (asserts! (not (get-shutdown-activated)) (err ERR-EMERGENCY-SHUTDOWN-ACTIVATED))
	  (asserts! (> amount u0) (err AMOUNT_ZERO))
    (asserts! (is-none (map-get? Account tx-sender)) (err ERR_DEPOSITED_ALREADY))
    ;; (try! (contract-call? .cwe004-chain-nft mint-nft- tx-sender))
    (map-insert Account tx-sender {chain-id: id, deposited: true} )
    (map-set staker-lockup  { staker: tx-sender } { start-block: block-height })

    (var-set last-chain-id id)
    (unwrap-panic (create-chain id recipients))
    (unwrap-panic (add-deposit amount))
    (ok true)
)
)
)

(define-public (deposit-with-chain-challange (amount uint) (recipients principal))
(let (
    (staker tx-sender)
    (id (+ u1 (var-get last-chain-id)))
    ;; (chain-id (get-users-nonce staker))
    (recipient (unwrap-panic (get-recipients u1 recipients)))
  )
  (begin 

    ;; (asserts! (not (get-shutdown-activated)) (err ERR-EMERGENCY-SHUTDOWN-ACTIVATED))
	  (asserts! (> amount u0) (err AMOUNT_ZERO))
    (asserts! (is-none (map-get? Account tx-sender)) (err ERR_DEPOSITED_ALREADY))
    ;; (try! (contract-call? .cwe004-chain-nft mint-nft- tx-sender))
    (map-insert Account tx-sender {chain-id: id, deposited: true} )
    (map-set staker-lockup  { staker: tx-sender } { start-block: block-height })
    ;; (try! (contract-call? .cwe003-chain-challange go u"jjhhh" u"smd" amount (/ amount u100) block-height u3))

    (var-set last-chain-id id)
    (unwrap-panic (create-chain id recipients))
    (unwrap-panic (add-deposit amount))
    (ok true)
)
)
)

(define-public (add-deposit-challange (uamount uint))
  (let (
    (staker tx-sender) 
    ;; (chain-id (get-users-nonce staker))
    (current-collateral (get-collateral-amount-of staker))
    (current-total-collateral (var-get total-collateral))
    (chain (get-chain-by-id u1))
    (new-collateral (+ uamount (get collateral chain)))
    (updated-chain (merge chain {
      collateral: new-collateral,
      updated-at-block-height: block-height
    }))
  )
    (asserts! (is-eq contract-caller CONTRACT_OWNER) (err ERR-NOT-AUTHORIZED))
    (asserts! (is-eq (get is-liquidated chain) false) (err ERR-VAULT-LIQUIDATED))
    (asserts! (is-eq tx-sender (get owner chain)) (err ERR-NOT-AUTHORIZED))
    ;; (unwrap-panic (contract-call? .chain-reserves deposit .chain-usda uamount))
    ;; (unwrap-panic (add-collateral uamount tx-sender))

    ;; (try! (contract-call? .usda transfer uamount tx-sender (as-contract tx-sender) none))
    (unwrap-panic (update-chain u1 updated-chain))
    ;; (unwrap-panic (add-collateral uamount tx-sender))
    (var-set total-collateral (+ current-total-collateral uamount))
    (map-set owner-collateral { owner: staker } { collateral: new-collateral, cumm-reward-per-collateral: (var-get cumm-reward-per-collateral), chain-id: u1 })    
    (map-set chains (tuple (id u1)) {id: u1, owner: staker, collateral: new-collateral, collateral-type: "USDA", collateral-token: "USDA", debt: (get debt chain), created-at-block-height: block-height, updated-at-block-height: block-height, is-minted: false, is-liquidated: false, leftover-collateral: u0
    })
    (print { type: "chain", action: "deposit", data: updated-chain })
    (ok true)
  )
)
(define-public (add-deposit (uamount uint))
  (let (
    (staker tx-sender) 
    ;; (chain-id (get-users-nonce staker))
    (current-collateral (get-collateral-amount-of staker))
    (current-total-collateral (var-get total-collateral))
    (chain (get-chain-by-id u1))
    (new-collateral (+ uamount (get collateral chain)))
    (updated-chain (merge chain {
      collateral: new-collateral,
      updated-at-block-height: block-height
    }))
  )
    (asserts! (is-eq contract-caller CONTRACT_OWNER) (err ERR-NOT-AUTHORIZED))
    ;; (asserts! (is-eq (get is-liquidated chain) false) (err ERR-VAULT-LIQUIDATED))
    ;; (asserts! (is-eq tx-sender (get owner chain)) (err ERR-NOT-AUTHORIZED))
    ;; (unwrap-panic (contract-call? .chain-reserves deposit .chain-usda uamount))
    ;; (unwrap-panic (add-collateral uamount tx-sender))
    ;; (try! (contract-call? .usda transfer uamount tx-sender (as-contract tx-sender) none))
    ;; (unwrap-panic (update-chain chain-id updated-chain))
    ;; (var-set total-collateral (+ current-total-collateral uamount))
    ;; (map-set owner-collateral { owner: staker } { collateral: new-collateral, cumm-reward-per-collateral: (var-get cumm-reward-per-collateral), chain-id: chain-id })    
    ;; (map-set chains (tuple (id chain-id)) {id: chain-id, owner: staker, collateral: new-collateral, collateral-type: "USDA", collateral-token: "USDA", debt: (get debt chain), created-at-block-height: block-height, updated-at-block-height: block-height, is-minted: false, is-liquidated: false, leftover-collateral: u0
    ;; })
    (print { type: "chain", action: "deposit", data: updated-chain })
    (ok true)
  )
)

;; ---------------------------------------------------------
;; Redeem
;; ---------------------------------------------------------

(define-public (redeem (amount uint))
  (let (
    (staker tx-sender)
    ;; (chain-id (get-users-nonce staker))
    (stake-start-block (get start-block (get-staker-lockup staker)))
  )
  (begin 
    ;; (asserts! (not (get-shutdown-activated)) (err ERR-EMERGENCY-SHUTDOWN-ACTIVATED))
	  (asserts! (> amount u0) (err AMOUNT_ZERO))
    (asserts! (>= block-height (+ stake-start-block (var-get lockup-blocks))) (err ERR-STAKE-NOT-UNLOCKED))
    (remove-deposit amount)
  )
  )
)
(define-public (redeem-challange (amount uint))
  (let (
    (challanger tx-sender)
    ;; (chain-id (get-users-nonce challanger))
    )
  (begin 
    ;; (asserts! (not (get-shutdown-activated)) (err ERR-EMERGENCY-SHUTDOWN-ACTIVATED))
	  (asserts! (> amount u0) (err AMOUNT_ZERO))
    (remove-deposit-challange amount)
  )
  )
)

(define-public (redeem-all)
  (let (
    (challanger tx-sender)
    (collateral (get-collateral-amount-of challanger))
  ) 
    
     (remove-deposit collateral))
)
(define-public (redeem-all-challange)
  (let (
    (challanger tx-sender)
    (collateral (get-collateral-amount-of challanger))
  ) 
    
     (remove-deposit-challange collateral))
)

(define-public (redeem-transfer (recipient principal) (amount uint))
  (remove-collateral amount recipient)
)

(define-public (redeem-transfer-all (recipient principal))
  (let (
    (owner tx-sender)
    (collateral (get-collateral-amount-of owner))
  ) 
  (remove-collateral collateral recipient))
)

(define-public (remove-deposit (uamount uint))
  (let (
    (staker tx-sender)
    ;; (chain-id (get-users-nonce staker))
    (chain (get-chain-by-id u1))
    (new-collateral (- (get collateral chain) uamount))
    (updated-chain (merge chain {
      collateral: new-collateral,
      updated-at-block-height: block-height
    }))
  )
  
    (asserts! (is-eq contract-caller CONTRACT_OWNER) (err ERR-NOT-AUTHORIZED))
    (asserts! (is-eq (get is-liquidated chain) false) (err ERR-VAULT-LIQUIDATED))
    (asserts! (is-eq tx-sender (get owner chain)) (err ERR-NOT-AUTHORIZED))
    (unwrap-panic (update-chain u1 updated-chain))
    (unwrap-panic (remove-collateral uamount tx-sender))
    (print { type: "chain", action: "deposit", data: updated-chain })
    (ok true)
  )
)
(define-public (remove-deposit-challange (uamount uint))
  (let (
    (challanger tx-sender)
    ;; (u1 (get-users-nonce challanger))

    (chain (get-chain-by-id u1))
    (new-collateral (- (get collateral chain) uamount))
    (updated-chain (merge chain {
      collateral: new-collateral,
      updated-at-block-height: block-height
    }))
    (challanger-end-block (get end-block (get-challanger-lockup challanger)))

  )

    (asserts! (>= block-height challanger-end-block) (err ERR-STAKE-NOT-UNLOCKED))
    (asserts! (is-eq contract-caller CONTRACT_OWNER) (err ERR-NOT-AUTHORIZED))
    (asserts! (is-eq (get is-liquidated chain) false) (err ERR-VAULT-LIQUIDATED))
    (asserts! (is-eq tx-sender (get owner chain)) (err ERR-NOT-AUTHORIZED))
    (unwrap-panic (update-chain u1 updated-chain))
    (unwrap-panic (remove-collateral uamount tx-sender))
    (print { type: "chain", action: "deposit", data: updated-chain })
    (ok true)
  )
)

(define-public (remove-collateral (collateral uint) (owner principal))
  (let (
      (staker tx-sender)
    ;; (user-id (get-users-nonce staker))
    (id (get-chain-by-id u1))
    (current-collateral (get-collateral-amount-of owner))
    (new-collateral (- (get collateral id) collateral))
    (current-total-collateral (var-get total-collateral))
  )
    (var-set total-collateral (- current-total-collateral collateral))
    (map-set owner-collateral { owner: owner } { collateral: new-collateral, cumm-reward-per-collateral: (var-get cumm-reward-per-collateral), chain-id: u1 })
    
    (map-set meta u1 {
	  owner: owner,
	  chain-id: u1,
    listed: false,
    price: new-collateral})

    
(let (
      (chain { id: u1, owner: owner, collateral: new-collateral, collateral-type: "USDA", collateral-token: "USDA", debt: u0, created-at-block-height: block-height, updated-at-block-height: block-height, is-liquidated: false, is-minted: false, leftover-collateral: u0 })
    )
      (unwrap-panic (update-chain u1 chain))

      ;; (try! (as-contract (contract-call? .usda transfer collateral .chain-pool staker none)))

      (print { type: "vault", chain: "created", data: chain })
      (ok chain)
    )
  )
)
;; ---------------------------------------------------------
;; Chain Functions 
;; ---------------------------------------------------------

(define-public (create-chain (chain-id uint) (recipients principal)) 
  (begin 
   (unwrap-panic (create-chain-internal chain-id recipients)) 
   (ok true)
  )
)

(define-public (update-owner (recipient principal)) 
   (let (
    (chain-id (get-chain-id-of tx-sender))
     ) 
      (update-owner-internal chain-id recipient))
)

(define-public (change-chain (recipient principal)) 
   (let (
    (chain-id (get-chain-id-of tx-sender))
     ) 
      (change-chain-internal chain-id recipient))
)

(define-public (update-recipient  (recipient principal)) 
   (let (
    (chain-id (get-chain-id-of tx-sender))
     ) 
      (update-recipient-internal chain-id recipient))
)

(define-public (add-recipient (recipient principal))
  (let (
    (chain-id (get-chain-id-of tx-sender))
  ) 
    (add-recipient-internal chain-id recipient)
  )
)

(define-public (remove-recipient (recipient principal))
  (let (
    (chain-id (get-chain-id-of tx-sender))
  ) 
    (remove-recipient-internal chain-id recipient)
  )
)

;; ---------------------------------------------------------
;; Withdraw
;; ---------------------------------------------------------

;; @desc max amount of USDA that can be withdrawn for liquidations
;; (define-read-only (max-withdrawable-usda)
;;   (let (
;;     (usda-balance (unwrap-panic (contract-call? .usda get-balance (as-contract tx-sender))))
;;     (usda-to-keep u1000000000) ;; always keep 1k USDA
;;   )
;;     (if (<= usda-balance usda-to-keep)
;;       (ok u0)
;;       (ok (- usda-balance usda-to-keep))
;;     )
;;   )
;; )




(define-public (mint (extra-debt uint) (coll-type <collateral-types-trait>))
  (let (
    (staker tx-sender)
    (chain-id (get-chain-id-of staker))
    (chain (get-chain-by-id chain-id))    
    (new-total-debt (+ extra-debt (get debt chain)))
    (is-minted (get is-minted chain))
    (collateral-type (unwrap-panic (contract-call? coll-type get-collateral-type-by-name (get collateral-type chain))))
    (fee (/ new-total-debt u10))
    ;; (mint-tokens (try! (contract-call? .cwe005-chain-reserves mint (get collateral-token chain) (get owner chain) (get collateral chain) (get debt chain) extra-debt (get collateral-to-debt-ratio collateral-type))))
    (updated-chain (merge chain { debt: new-total-debt, updated-at-block-height: block-height, is-minted: true}))
    (ratio (unwrap! (calculate-current-collateral-to-debt-ratio- (get collateral-token chain) new-total-debt (get collateral chain))
    (err ERR-WRONG-DEBT)))
    (end-block (+ block-height (get start-block (get-staker-lockup staker)) (var-get lockup-blocks)))
  )
    (asserts! (is-eq (get is-liquidated chain) false) (err ERR-VAULT-LIQUIDATED))
    (asserts! (<= new-total-debt (get collateral chain)) (err ERR-MAXIMUM-DEBT-REACHED))
    (asserts!
      (or
        (asserts! (is-eq is-minted true) (ok (begin
            (map-set chains (tuple (id chain-id)) updated-chain)
                ;; (try! (contract-call? .cwe001-chain-stream create-stream .cwe005-chain-reserves fee block-height end-block .cwe000-chain-usda))
                ;; mint-tokens
                ))
                
                )
        (asserts! (is-eq is-minted true) 
        (ok 
          (begin 
            (let (
             (stream (unwrap-panic (get-stream chain-id)))
             (coll u0)
              (amount-to-pay (* (get rate-per-seconds stream) (sub-up block-height (get start-time stream))))
              (collateral (get-collateral-amount-of staker))
             (real-time-balance (- (* collateral u1000000000) amount-to-pay))
             (chain-time-balance (+ (-  collateral real-time-balance) coll))

            (updated-collateral (merge chain { collateral: real-time-balance, updated-at-block-height: block-height}))
            ) (begin  
      ;;  (try! (contract-call? .cwe001-chain-stream create-stream .cwe005-chain-reserves fee block-height end-block .cwe000-chain-usda))                
       (map-set chains (tuple (id chain-id)) updated-collateral)
            )))
        )
        
        )
      )
      (err ERR-NOT-AUTHORIZED)
    )
  (begin 

  (map-set chains (tuple (id chain-id)) updated-chain)
  (unwrap-panic (get-dynamic))
  (print { type: "chain", action: "mint", data: updated-chain})


      (ok true)

)
  )
  )


(define-public (get-dynamic) 
  (let (
    (staker tx-sender)
    (chain-id (get-chain-id-of staker))
    (chain (get-chain-by-id chain-id))    
    (stream (unwrap-panic (get-stream chain-id)))
    (data (unwrap-panic (get-meta chain-id)))
    (amount-to-pay (* (get rate-per-seconds stream) (sub-up block-height (get start-time stream))))
    (collateral (get-collateral-amount-of staker))
    (real-time-balance (- (* collateral u1000000000) amount-to-pay))
    (updated-loan (merge chain { collateral: real-time-balance }))       
)
    (map-set dynamic-balance {chain-id: chain-id} {real-time-balance: real-time-balance, collateral-payed: amount-to-pay, last-accrued: block-height})
    (map-set chains (tuple (id chain-id)) updated-loan)  
    (map-set meta chain-id (merge data { price: real-time-balance }))
    (ok real-time-balance)
  )
)


(define-public (burn (extra-debt uint) (coll-type <collateral-types-trait>))
  (let (
    (staker tx-sender)
    (chain-id (get-chain-id-of staker))
    (chain (get-chain-by-id chain-id))    
    (new-total-debt (- extra-debt (get debt chain) ))
    (updated-chain (merge chain {
      debt: new-total-debt,
      updated-at-block-height: block-height
    }))
    (collateral-type (unwrap-panic (contract-call? coll-type get-collateral-type-by-name (get collateral-type chain))))

  )
    ;; (asserts!
    ;;   (and
    ;;     (is-eq (unwrap-panic (contract-call? .chain-dao get-emergency-shutdown-activated)) false)
    ;;     (is-eq (var-get freddie-shutdown-activated) false)
    ;;   )
    ;;   (err ERR-EMERGENCY-SHUTDOWN-ACTIVATED)
    ;; )
    (asserts! (is-eq (get is-liquidated chain) false) (err ERR-VAULT-LIQUIDATED))
  
    ;; ;; save how much stability fees the person owes up to that point
    ;; (try! (contract-call? .cwe005-chain-reserves burn
    ;;     .cwe000-chain-usda
    ;;     (get owner chain)
    ;;     extra-debt
    ;;   )
    ;; )
    (unwrap-panic (update-chain chain-id updated-chain))
    (print { type: "chain", action: "mint", data: updated-chain })
    (ok true)
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

(define-public (update-loan (chain-id uint) (data (tuple (id uint) (startTime uint) (stopTime uint) (interest uint) (ratePerSecond uint)  (dynamic-collateral uint) (stability-fee-last-accrued uint) (stability-fee-accrued uint))))
  (let (
    (chain (get-chain-by-id chain-id)))
    (asserts! (is-eq contract-caller CONTRACT_OWNER) (err ERR-NOT-AUTHORIZED))
    (map-set chain-stream (tuple (id chain-id)) data)
    (ok chain)
  )
)

(define-private (get-recipients (chain-id uint) (recipient principal)) 
  (ok 
    (unwrap! (as-max-len? (append (get-benificary chain-id ) recipient) u200) ERR-TOO-MANY-POOLS)
  )
)

(define-private (create-chain-internal (chain-id uint) (recipient principal)) 
  (let (
    (recipients (unwrap-panic (get-recipients chain-id recipient)))
  )
    (map-set Chains chain-id  { chain-id: chain-id , owner: tx-sender, recipient: recipient, portions: DEFAULT_PORTION, recipients: none }) 
    (map-set benificary chain-id recipients)
    (ok chain-id)
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
      (map-set Chains chain-id (merge chain { chain-id: chain-id , owner: new-owner }))
      (map-set meta (var-get last-chain-id) (merge data {owner: new-owner}))
      (unwrap-panic (update-owner-internal chain-id new-owner))
      (ok true)
    )
  )
)

(define-private (update-owner-internal (chain-id uint) (new-owner principal)) 
  (begin 
    (let (
    (chain (unwrap-panic (map-get? Chains chain-id)))
    (id (get chain-id chain))
    (data (unwrap-panic (get-meta id)))
    )
      (map-set meta chain-id (merge data {owner: new-owner }))
      (map-set Chains chain-id (merge chain {chain-id: chain-id, owner: new-owner}))

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
    (map-set Chains chain-id (merge chain { recipient: recipient}))
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
    )
      (map-set benificary chain-id recipients)
      (map-set Chains chain-id (merge chain {chain-id: chain-id, portions: val,recipients: (some recipients)}))

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
      (map-set Chains chain-id (merge chain {chain-id: chain-id, recipients: (some deleteRecipients)}))
    )	
   (ok true)
  )
)

(define-private (remove-recipent-filter (recipient principal))
  (not (is-eq recipient))
)

;; ---------------------------------------------------------
;; Update
;; ---------------------------------------------------------

(define-public (update-lockup (blocks uint))
  (begin
    ;; (asserts! (is-eq tx-sender (contract-call? .arkadiko-dao get-dao-owner)) (err ERR-NOT-AUTHORIZED))

    (var-set lockup-blocks blocks)
    
    (ok true)
  )
)


;; (begin (deposit-with-new-chain tx-sender u100))


(define-private (remove-burned-chain (chain-id uint))
  (let ((current-chain (unwrap-panic (map-get? closing-chain { user: tx-sender }))))
    (if (is-eq chain-id (get chain-id current-chain))
      false
      true
    )
  )
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

;; (begin (deposit u1000 ))
;; (begin (add-deposit u1000))
(define-read-only (sub-up (a uint) (b uint))
    (let
        (
            (subtract (- a b))
       )
        (if (<= subtract u0)
            u0
            subtract
       )
   )
)