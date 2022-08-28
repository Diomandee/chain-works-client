(use-trait chain-pool-trait .chain-pool-trait.chain-pool-trait)
(use-trait collateral-types-trait .collateral-types-trait.collateral-types-trait)
;; (use-trait nft-trait .nft-trait.nft-trait)
(use-trait ft-trait .sip010-ft-trait.sip010-ft-trait)

;; constants
(define-constant CYCLE_PERIOD u144)
(define-constant ERR-ALREADY-JOINED (err u405))
(define-constant ERR-JOIN-FAILED (err u500))
(define-constant DEFAULT-PRICE u100)
(define-constant CONTRACT_OWNER tx-sender)
(define-constant CONTRIBUTION u100)
(define-constant DEFAULT_PORTION u100)

;; Errors
(define-constant ERR-NOT-AUTHORIZED u32401)
(define-constant ERR-UNSTAKE-AMOUNT-EXCEEDED u32002)
(define-constant ERR-WITHDRAWAL-AMOUNT-EXCEEDED u32003)
(define-constant ERR-STAKE-NOT-UNLOCKED u32005)
(define-constant ERR-TOO-MANY-POOLS (err u2004))
(define-constant AMOUNT_ZERO u410)
(define-constant ERR_DEPOSITED_ALREADY u411)
(define-constant ERR_BAD_REQUEST (err u400))
(define-constant ERR_UNAUTHORIZED (err u401))
(define-constant ERR_FORBIDDEN (err u403))
(define-constant ERR_CHALLENGE_NOT_FOUND (err u404))
(define-constant ERR_TIMEOUT_IN_PAST (err u407))
(define-constant ERR_TIMEOUT_NOT_REACHED (err u408))
(define-constant ERR_CONSENSUS_PERIOD_TIMEDOUT (err u409))
(define-constant ERR_ZERO_VALUE (err u410))
(define-constant ERR_PENALTY_GREATER_VALUE (err u400))
(define-constant ERR_NOT_EQUAL (err u401))
(define-constant ERR_START_TIME_BEFORE (err u414))

;; data maps and vars

;; private functions
(define-private (increment-lobby-count)
  (begin
    (var-set lobby-count (+ (var-get lobby-count) u1))
    (var-get lobby-count)
  )
)

(define-private (add-balance (id uint) (participant principal) (amount uint))
  (begin
    ;; (unwrap-panic (stx-transfer? amount participant (as-contract tx-sender)))
    (match
      (map-get? lobbies {id: id})
      lobby
      (map-set lobbies {id: id} (merge lobby {balance: (+ (default-to u0 (get balance (map-get? lobbies {id: id}))) amount)}))
      false
    )
  )
)




;; Variables
(define-data-var fragments-per-token uint u1000000000000)
(define-data-var total-fragments uint u0)
(define-data-var shutdown-activated bool false)
(define-data-var last-chain-id uint u0)
(define-data-var total-collateral uint u0) 
(define-data-var cumm-reward-per-collateral uint u0) 
(define-data-var last-reward-increase-block uint u0) 
(define-data-var vault-rewards-shutdown-activated bool false)
(define-data-var lobby-count uint u0)
(define-data-var contract-owner principal tx-sender)

;; ---------------------------------------------------------
;; Maps
;; ---------------------------------------------------------

(define-map submited principal bool)

(define-map benificary uint (list 200 principal))
(define-map host uint (list 200 principal))

(define-map Account principal {chain-id: uint, deposited: bool})

(define-map allowances {spender: principal, owner: principal} {allowance: uint})


(define-map Chains uint {
  chain-id: uint,
  owner: principal, 
  totalValue: uint,
  portions: uint,
  recipients: (list 200 principal),
  co-host: (optional (list 200 principal)),
})

(define-map lobbies {id: uint} {owner: principal, description: (string-utf8 2048), balance: uint, value: uint, missedPenalty: uint, startTime: uint, name: (string-utf8 2048), days: uint, active: bool})

(define-map scoreboard {lobby-id: uint, address: principal} {score: uint, rank: uint, sum-rank-factor: uint, rank-factor: uint, rewards: uint, rac: uint, nft: (string-ascii 99)})



(define-map chain-entries { user: principal } { ids: (list 20 uint) })

(define-map closing-chain { user: principal } { chain-id: uint })

(define-map staker-fragments { staker: principal} { fragments: uint})
(define-map dynamic-balance { chain-id: uint, challanger: principal} 
  {
    real-time-balance: uint,
    collateral-payed: uint,
    last-accrued: uint
  }
)
(define-map Challanges uint {
	creator: principal,	
    challangeName: (string-utf8 2048),		;; player address	;; prediction event 
    challangeRules: (string-utf8 2048),		;; player address	;; prediction event 
	contributionValue: uint,				;; amount at stake in micro-stx
	timeout: uint,
	startTime: uint,
	isEntity: bool, 
	recipients: (optional (list 200 principal)),
	claim: (optional {								
		creatorClaim : uint,		;; stores self declaration of victory by creator
		challengerClaim : uint	;; stores self declaration of victory by challenger		;; stores judged 	;; stores $VERITY amount at the time of accept step
	}),
	rep: (optional {								
		creatorRep : uint,				;; stores $VERITY amount at the time of accept step
		challengerRep : uint,
					;; stores $VERITY amount at the time of accept step
	})
}) 
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

(define-map challangeInfo uint {
	cycles: uint,
  cycleLength: uint,
  checkInFreq: uint,
	challangeDuration: uint,
  penalty: uint,
	stopTime: uint,
	startTime: uint,
	recipients: (optional (list 200 principal)),

} 
)

;; ---------------------------------------------------------
;; Getters
;; ---------------------------------------------------------


(define-read-only (get-chain (chain-id uint))
  (map-get? Chains chain-id))

(define-read-only (get-challange-info (challange-id uint))
  (map-get? challangeInfo challange-id )
  )

(define-read-only (get-stream (stream-id uint)) 
  (contract-call? .cwe001-chain-stream get-stream stream-id))

(define-read-only (get-collateral-amount-of (owner principal))
  (get collateral (get-collateral-of owner))
)
(define-read-only (get-chain-id-of (owner principal))
  (get chain-id (get-collateral-of owner))
)
(define-read-only (get-challange (challangeId uint))
  (map-get? Challanges challangeId)
)
(define-read-only (get-meta (id uint))
  (map-get? meta id))

(define-read-only (get-account (staker principal))
  (map-get? Account staker)
)


(define-read-only (get-dynamic-balance (chain-id uint) (challanger principal))
 
    (map-get? dynamic-balance { chain-id: chain-id, challanger: challanger })
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

(define-read-only (get-collateral-of (owner principal))
  (default-to
    { collateral: u0, cumm-reward-per-collateral: u0, chain-id: u0}
    (map-get? owner-collateral { owner: owner })
  )
)

(define-read-only (get-chain-entries (user principal))
  (unwrap! (map-get? chain-entries { user: user }) (tuple (ids (list u0) )))
)

(define-read-only (get-benificary (chain-id uint))
    (default-to (list) (map-get? benificary chain-id ))
)
(define-read-only (get-host (chain-id uint))
    (default-to (list) (map-get? host chain-id ))
)

;; @desc get current lockup time
(define-read-only (get-total-collateral)
  (ok (var-get total-collateral))
)

(define-data-var contract-is-enabled bool true)


(define-map epoch principal {
  epoch-length: uint,
  epoch-number: uint,
  epoch-end-block: uint,
  epoch-start-block: uint,
})
(define-data-var epoch-length uint u0)
(define-data-var epoch-number uint u0)
(define-data-var epoch-end-block uint u0)
(define-data-var epoch-start-block uint u0)

;; ------------------------------------------
;; Var & Map Helpers
;; ------------------------------------------

(define-read-only (get-lobby (id uint))
    (ok (unwrap-panic (map-get? lobbies {id: id})))
)

(define-read-only (get-epoch-length )
 (var-get epoch-length))

(define-read-only (get-epoch-number)
  (var-get epoch-number)
)
(define-read-only (get-epoch-end-block)
  (var-get epoch-end-block)
)
(define-read-only (get-epoch-start-block)
  (var-get epoch-start-block)
)


(define-public (update-epoch (id uint) (length uint) (number uint))
 (let (
  (lobes (unwrap-panic (map-get? lobbies {id: id})))
  (info (unwrap-panic (map-get? challangeInfo id)))
  (start (get startTime lobes))
 )
  (begin 
    (map-set epoch tx-sender {epoch-length: u0,epoch-number: u0, epoch-end-block: (+ block-height (get stopTime info)),epoch-start-block: (+ block-height (+ start (get cycleLength info)))})
  (ok lobes)
)))




;; public functions
;; anyone can create a challange
(define-public (create-challange (name (string-utf8 2048)) (description (string-utf8 2048)) (value uint) (missedPenalty uint) (startTime uint) (days uint))
    (let (
      (lobby-id (increment-lobby-count))
      (cycles (/ value missedPenalty))
      (cycleLength (* days u144))
      (duration (* cycles cycleLength)) 
      (timeout (+ startTime duration))
    )
    (asserts! (not (is-eq name u"")) ERR_BAD_REQUEST)
		(asserts! (not (is-eq description u"")) ERR_BAD_REQUEST)
    (asserts! (> value u0) ERR_ZERO_VALUE) 
	  (asserts! (> days u0) ERR_ZERO_VALUE)
	  (asserts! (>= startTime block-height) ERR_START_TIME_BEFORE)
	  (asserts! (> value missedPenalty) ERR_PENALTY_GREATER_VALUE)
    

    (map-set lobbies {id: lobby-id} { owner: tx-sender,name: name, description: description, balance: value, value: value, missedPenalty: missedPenalty, startTime: startTime, days: days, active: true})

    (map-set epoch tx-sender {epoch-length: u0,epoch-number: u0,epoch-end-block: timeout,epoch-start-block: (+ startTime cycleLength)})
    (unwrap-panic (create-chain lobby-id))
        ;; (try! (contract-call? .chain-dao chain-nft-mint lobby-id .chain-dao cycles))

    (unwrap-panic (add-deposit-challange lobby-id value))
     (map-set challangeInfo lobby-id { stopTime:  timeout, startTime: block-height, penalty: missedPenalty, cycles: cycles, checkInFreq: cycles, cycleLength: cycleLength,  challangeDuration: duration, recipients: none,
    })
        ;; (unwrap-panic (contract-call? .chain-stream create-stream .chain-dao value startTime timeout .chain-usda ))
        (ok lobby-id)
    )
)


(define-public (challange-rules (nft-token-id {chain-id: uint, owner: principal}))
	(ok	true)
	)

(define-private (challange-starts) (ok u3))
(define-private (cut-off-time) (ok u3))
(define-private (max-check-per-day) (ok u3))
(define-private (is-acceptable-check-in) (ok u3))
(define-public (flag-check-in) (ok u3))
(define-public (check-up-in) (ok u3))

;; public functions
;; anyone can create a challange

(define-public (give-up-penalty (id uint)) 
(ok u3)
)

(define-public (join-stream (id uint))
    (let (
        (lobes (unwrap-panic (map-get? lobbies {id: id})))
        (info (unwrap-panic (map-get? challangeInfo id)))
        (owner ( get owner lobes))
        (stop (+ block-height (get stopTime info)))
        (current-collateral (get-collateral-amount-of owner))
        (chain-id  (var-get last-chain-id))
        (anchor (unwrap-panic (element-at (get-benificary id) chain-id)))
        (entry-price (default-to DEFAULT-PRICE (get value (map-get? lobbies {id: id}))))
        (joined (map-insert scoreboard {lobby-id: id, address: tx-sender} {score: u0, rank: u0, sum-rank-factor: u0, rank-factor: u0, rewards: u0, rac: u0, nft: ""})))
        (var-set last-chain-id (+ u1 chain-id))
        (unwrap-panic (map-get? lobbies {id: id}))
        (asserts! joined ERR-ALREADY-JOINED)
        (asserts! (not (is-eq tx-sender owner)) ERR_FORBIDDEN)
        (add-balance id tx-sender entry-price)
        (unwrap-panic (add-deposit-challange id entry-price))
        (unwrap-panic (add-recipient id tx-sender))
        (unwrap-panic (update-epoch id block-height stop))
        ;; (try! (contract-call? .chain-dao chain-nft-mint id .chain-dao (get cycles info)))
        (print {action: "join", lobby-id: id, address: tx-sender })
        (ok chain-id)
    )
)


(define-public (join-challange (id uint))
    (let (
        (lobes (unwrap-panic (map-get? lobbies {id: id})))
        (info (unwrap-panic (map-get? challangeInfo id)))
        (owner ( get owner lobes))
        (stop (+ block-height (get stopTime info)))
        (current-collateral (get-collateral-amount-of owner))
        (chain-id  (var-get last-chain-id))
        (anchor (unwrap-panic (element-at (get-benificary id) chain-id)))
        (entry-price (default-to DEFAULT-PRICE (get value (map-get? lobbies {id: id}))))
        (joined (map-insert scoreboard {lobby-id: id, address: tx-sender} {score: u0, rank: u0, sum-rank-factor: u0, rank-factor: u0, rewards: u0, rac: u0, nft: ""})))
        (var-set last-chain-id (+ u1 chain-id))
        (unwrap-panic (map-get? lobbies {id: id}))
        (asserts! joined ERR-ALREADY-JOINED)
        (asserts! (not (is-eq tx-sender owner)) ERR_FORBIDDEN)
        (add-balance id tx-sender entry-price)
         (unwrap-panic (add-deposit-challange id entry-price))
        (unwrap-panic (add-recipient id tx-sender))
        (unwrap-panic (update-epoch id block-height stop))
        ;; (try! (contract-call? .chain-dao chain-nft-mint id .chain-dao (get cycles info)))
        (print {action: "join", lobby-id: id, address: tx-sender })
        (ok chain-id)
    )
)

(define-read-only (get-score (lobby-id uint) (address principal))
    (ok (unwrap-panic (map-get? scoreboard {lobby-id: lobby-id, address: address})))
)

(define-map checkedIn uint {challangeId: uint, cycle: uint, isCheckedin: bool, account: principal} )

(define-read-only (is-checked-in (challangeId uint) (number uint)) 
  (default-to { challangeId: challangeId, cycle: number , isCheckedin: false, account: tx-sender}
 (map-get? checkedIn number)))


(define-public (stake (challangeId uint) (isCheckedin bool))
  (let (
	(length (var-get epoch-length))
	(number (var-get epoch-number))
	(start-block (var-get epoch-start-block))
	(challenge (unwrap! (map-get? Challanges challangeId) ERR_CHALLENGE_NOT_FOUND))
	(challange_Info (unwrap! (map-get? challangeInfo challangeId) ERR_CHALLENGE_NOT_FOUND))
  (penalty (get penalty challange_Info))
  (cycleLength (get cycleLength challange_Info))
  (cycles (get cycles challange_Info))
  (current-collateral (get-collateral-amount-of tx-sender))
  (new-collateral (- current-collateral penalty))
  (chain (unwrap-panic (map-get? Chains challangeId)))
  (recipients (get recipients chain))

  )
	(asserts! (> block-height (- start-block u100)) ERR_START_TIME_BEFORE)
	(asserts! (< block-height start-block) (ok 
  (begin
    (var-set epoch-length (+ length cycleLength)) 
    (var-set epoch-start-block (+ (var-get epoch-start-block) cycleLength))
    (var-set epoch-number (+ number u1))
	  (map-set checkedIn number {challangeId: challangeId, cycle: number, isCheckedin: false, account: tx-sender})
    (map-set owner-collateral { owner: tx-sender } { collateral: new-collateral, cumm-reward-per-collateral: (var-get cumm-reward-per-collateral), chain-id: challangeId}) 
  )))

  	;; (asserts! (is-eq amount penalty) ERR_FORBIDDEN)
	  ;; (asserts! (is-eq tx-sender creator) ERR_FORBIDDEN)
  (begin

    (var-set epoch-length (+ length cycleLength)) 
    (var-set epoch-start-block (+ (var-get epoch-start-block) cycleLength))
    ;; (var-set epoch-start-block (+ (fold + (list cycleLength startTime) startTime)))
    (var-set epoch-number (+ number u1)) 
	  (map-set checkedIn number { challangeId: challangeId,  cycle: number, isCheckedin: isCheckedin,  account: tx-sender })
  )
    ;; (try! (contract-call? .chain-nft transfer-ft (/ cycles u10) tx-sender (as-contract tx-sender) none))
    (print {action: "claim", who: tx-sender, challenge: challenge})
    (ok (var-set epoch-length (+ length cycleLength)))
  )
)

(define-public (accept (challangeId uint))
	(let (
		(info (unwrap-panic (get-challange-info challangeId)))
    (owner (get owner (unwrap-panic (get-chain challangeId))))
    (collateral (unwrap-panic (get-chain challangeId)))
    (recipients (get-benificary challangeId))
    )
     (begin    
      (asserts! (is-eq tx-sender owner) ERR_FORBIDDEN)
      (asserts! (is-none (get-stream challangeId)) (err ERR_DEPOSITED_ALREADY))

    ;;   (try! (contract-call? .chain-dao chain-ft-mint challangeId .chain-dao (get totalValue collateral)))
      )
      (unwrap-panic (contract-call? .chain-dao build-stream challangeId recipients (get totalValue collateral) (get startTime info) (get stopTime info)) )
		(print {action: "claim", who: tx-sender, participator: recipients, challenge: info})
		(ok recipients)
	)
)

(define-public (get-dynamic) 
  (let (
    (staker tx-sender)
    (chain-id (get-chain-id-of staker))
    (stream (unwrap-panic (get-stream chain-id)))
    (amount-to-pay (* (get rate-per-seconds stream) (sub-up block-height (get start-time stream))))
    (collateral (get-collateral-amount-of staker))
    (real-time-balance (* collateral u1000000000))
         
)
    (map-set dynamic-balance {chain-id: chain-id, challanger: staker} {real-time-balance: real-time-balance, collateral-payed: amount-to-pay, last-accrued: block-height})
    
    (ok (get-dynamic-balance chain-id staker))
  )
)

;; (define-private (add-anchor (owner principal) (challangeId uint) (collateral uint) (startTime uint) (stopTime uint))

;;  (contract-call? .chain-dao build-anchor owner challangeId  collateral startTime stopTime )
;; )


(define-private (add-deposit-challange (id uint) (uamount uint))
  (let (
    (staker tx-sender) 
    (current-collateral (get-collateral-amount-of staker))
    (current-total-collateral (var-get total-collateral))
    (new-collateral (+ uamount current-collateral))
  )
    (map-set staker-lockup  { staker: staker } { start-block: block-height })
    (map-set Account tx-sender {chain-id: id, deposited: true})
    ;; (try! (contract-call? .chain-dao deposit uamount))
    (var-set total-collateral (+ current-total-collateral uamount))
    (map-set owner-collateral { owner: staker } { collateral: new-collateral, cumm-reward-per-collateral: (var-get cumm-reward-per-collateral), chain-id: id})    
    (ok true)
  )
)

(define-private (remove-deposit-challange (id uint) (uamount uint)) 
  (let (
    (staker tx-sender)
    (challenge (unwrap! (map-get? Challanges id) ERR_CHALLENGE_NOT_FOUND))
    (current-collateral (get-collateral-amount-of staker))
		(startTime (get startTime challenge))
    (new-collateral (- current-collateral uamount))
    ;; (challanger-end-block (get end-block (get-challanger-lockup staker)))
  )
    (asserts! (< block-height startTime) (err ERR-STAKE-NOT-UNLOCKED))
    (map-set owner-collateral { owner: staker } { collateral: new-collateral, cumm-reward-per-collateral: (var-get cumm-reward-per-collateral), chain-id: id})    
    ;; (try! (contract-call? .chain-dao withdraw-collateral uamount staker))
    (print { type: "chain", action: "deposit" })
    (ok true)
  )
)
;; ---------------------------------------------------------
;; Redeem
;; ---------------------------------------------------------

(define-public (redeem-challange (id uint) (amount uint))
   (begin 
    ;; (asserts! (not (get-shutdown-activated)) (err ERR-EMERGENCY-SHUTDOWN-ACTIVATED))
	  (asserts! (> amount u0) (err AMOUNT_ZERO))
    (remove-deposit-challange id amount)
   )
 )


(define-public (redeem-all-challange (id uint))
  (let (
    (challanger tx-sender)
    (collateral (get-collateral-amount-of challanger))
  ) 
    (remove-deposit-challange id collateral))
)


;; ---------------------------------------------------------
;; Chain Functions 
;; ---------------------------------------------------------

(define-public (create-chain (chain-id uint)) 
  (begin 
   (unwrap-panic (create-chain-internal chain-id tx-sender)) 
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

(define-public (add-recipient (id uint) (recipient principal))
  (let (
    (chain-id (get-chain-id-of tx-sender))
  ) 
    (add-recipient-internal id recipient)
  )
)

(define-public (add-host (id uint) (recipient principal))
  (let (
    (chain-id (get-chain-id-of tx-sender))
  ) 
    (add-host-internal id recipient)
  )
)

(define-public (remove-recipient (recipient principal))
  (let (
    (chain-id (get-chain-id-of tx-sender))
  ) 
    (remove-recipient-internal chain-id recipient)
  )
)


(define-private (get-recipients (chain-id uint) (recipient principal)) 
  (ok 
    (unwrap! (as-max-len? (append (get-benificary chain-id ) recipient) u200) ERR-TOO-MANY-POOLS)
  )
)

(define-private (get-hosts (chain-id uint) (recipient principal)) 
  (ok 
    (unwrap! (as-max-len? (append (get-host chain-id ) recipient) u200) ERR-TOO-MANY-POOLS)
  )
)

(define-private (create-chain-internal (chain-id uint) (recipient principal)) 
  (let (
    (recipients (unwrap-panic (get-recipients chain-id recipient)))
    (challenge (unwrap! (map-get? lobbies {id: chain-id}) ERR_CHALLENGE_NOT_FOUND))
		(contributionValue (get value challenge))
  )
    (map-set Chains chain-id  { chain-id: chain-id , owner: tx-sender, portions: DEFAULT_PORTION, recipients: recipients, totalValue: contributionValue, co-host: none}) 
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
    ;;   (try! (contract-call? .chain-nft tag-nft-token-id-transfer new-owner {chain-id: chain-id, owner: tx-sender}))
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
(define-private (add-host-internal (chain-id uint) (new-owner principal)) 
  (begin 
    (let (
    (chain (unwrap-panic (map-get? Chains chain-id)))
    (id (get chain-id chain))
    (data (unwrap-panic (get-meta id)))
    (hosts (unwrap-panic (get-hosts chain-id new-owner))))
    
    (map-set meta chain-id (merge data {owner: new-owner }))
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

;; ---------------------------------------------------------
;; Update
;; ---------------------------------------------------------


;; (begin (deposit-with-new-chain tx-sender u100))


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
(begin (create-challange u"jjhhh" u"smd" u100 u10 u0 u3) )
;; (begin (create-challange u"jjhhh" u"smd" u100 u20 u0 u3) )
