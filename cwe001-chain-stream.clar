(use-trait Ft-trait .sip010-ft-trait.sip010-ft-trait)


;; Error Codes
;;
(define-constant ERR_UNAUTHORIZED (err u401))
(define-constant ERR_STREAM_NOT_FOUND (err u404))
(define-constant ERR_WITHDRAW_GREATER_BALANCE (err u405))
(define-constant ERR_BALANCE_GREATER_DEPOSIT (err u406))
(define-constant ERR_TIMEOUT_IN_PAST (err u407))
(define-constant ERR_TIMEOUT_NOT_REACHED (err u408))
(define-constant ERR_CONSENSUS_PERIOD_TIMEDOUT (err u409))
(define-constant ERR_ZERO_VALUE (err u410))
(define-constant ERR_DEPOSIT_SMALLER_DELTA (err u412))
(define-constant ERR_DEPOSIT_NOT_MULTIPLE_DELTA (err u413))
(define-constant ERR_RECIPIENT_GREATER_BALANCE (err u411))
(define-constant ERR_AMOUNT_IS_ZERO (err u414))
(define-constant ERR_AMOUNT_EXCEEDS_BALANCE (err u415))
(define-constant ERR_SHOULD_NEVER_HAPPEN (err u419))
(define-constant ERR_NOT_RECIPENT_OR_SENDER (err u400))
(define-constant ERR_STREAM_NOT_EXIST (err u401))
(define-constant ERR_START_TIME_BEFORE (err u419))
(define-constant ERR_NOT_PAYMENT_TOKEN (err u420))


;; Data Maps and Vars

(define-data-var streamNonce uint u0)
(define-data-var withdrawNonce uint u0)

(define-map Streams uint {
	sender: principal,	
    recipient: principal,				
	deposit: uint,
	startTime: uint,
    stopTime: uint,
	isEntity: bool,
	remainingBalance: uint,	
	rate: uint
})

(define-map BalanceOfLocalVars uint {
    recipientBalance: uint,
    withdrawalAmount: uint,
    senderBalance: uint,
    updated-at-block-height: uint
})
(define-map dynamic-balance {id: uint} {
    id: uint,
    recipientBalance: uint,
    withdrawalAmount: uint,
    senderBalance: uint,
    updated-at-block-height: uint
})

(define-map CreateStreamLocalVars uint {
    duration: uint,
    rate: uint
})

;; Helper Function

(define-read-only (create-stream-local-info (stream-id uint)) 
    (map-get? CreateStreamLocalVars stream-id))


(define-read-only (get-dynamic-balance (streamId uint))
   (map-get? dynamic-balance  {id: streamId}))

(define-read-only (withdraw-amount (rate uint) (startTime uint)) 
  (ok (* rate (sub-up block-height startTime))))

(define-read-only (get-stream (streamId uint))
  (map-get? Streams streamId))


(define-private (is-sender-or-recipient (stream-id uint)) 
    (let (
        (stream (unwrap! (get-stream stream-id) ERR_STREAM_NOT_FOUND))
        (sender (get recipient stream))
        (recipient (get recipient stream))
    )
    (asserts! (or (is-eq contract-caller sender) (is-eq contract-caller recipient)) ERR_UNAUTHORIZED)
    (ok true)
    )
)

(define-read-only (stream-exist (streamId uint)) 
    (let (
       (steamInfo (unwrap-panic (get-stream streamId )))
       (isEntity (get isEntity steamInfo)))

    (begin 
      (asserts! (is-some (get-stream streamId)) ERR_STREAM_NOT_FOUND)
      (asserts! (is-eq true (get isEntity steamInfo )) ERR_STREAM_NOT_FOUND)
      (ok true)
    )
  )
)

(define-read-only (stream-nonce)
	(ok (var-get streamNonce)))

(define-read-only (withdraw-nonce)
	(ok (var-get withdrawNonce)))

(define-public (delta-of (streamId uint)) 
 (let (
	   (stream (unwrap! (get-stream streamId) ERR_STREAM_NOT_FOUND))
       (stream-exis (unwrap! (stream-exist streamId) ERR_STREAM_NOT_EXIST))
       (startTime (get startTime stream))
       (stopTime (get stopTime stream))
       (timeStamp (default-to block-height (get-block-info? time block-height ))))
    (begin 
        (asserts! (is-eq stream-exis true) ERR_STREAM_NOT_EXIST)
        (asserts! (>= timeStamp startTime ) (ok u0))
        (asserts! (> timeStamp stopTime ) (ok (- timeStamp startTime)))
        (ok (- stopTime startTime))
    )
  )
) 

(define-public (create-stream (recipient principal) (deposit uint) (startTime uint) (stopTime uint))
	(let (
		(streamId (+ (var-get streamNonce) u1))
		(duration (sub-up stopTime startTime))
		(rate (div-up deposit duration))  
        (withdraw (/ (* rate (sub-up block-height startTime)) u100000000)))

        (asserts! (not (is-eq recipient tx-sender)) ERR_STREAM_NOT_FOUND)
		(asserts! (> stopTime block-height) ERR_TIMEOUT_IN_PAST)
		(asserts! (> deposit u0) ERR_ZERO_VALUE)
		(asserts! (>= deposit duration) ERR_DEPOSIT_SMALLER_DELTA)
		(asserts! (>= startTime block-height) ERR_START_TIME_BEFORE)
    (begin 
       (try! (stx-transfer? deposit tx-sender .cwe001-chain-stream))
    

       )
		(map-set Streams streamId { sender: tx-sender, startTime: startTime, stopTime: stopTime, remainingBalance: deposit, deposit: deposit,  recipient: recipient, isEntity: true, rate: rate})

		(map-set CreateStreamLocalVars streamId {duration: duration, rate: rate})
		(var-set streamNonce (+ streamId u1))
		(print {action: "start", who: tx-sender, streamId: streamId, stream: (get-stream streamId)})
		(ok streamId)
	)
)



(define-public (balance-of (streamId uint) (who principal))
    (begin 
      (let (
        (stream (unwrap! (get-stream streamId) ERR_STREAM_NOT_FOUND))
        (remainingBalance (get remainingBalance stream))

        (delta (unwrap-panic (delta-of streamId)))
        (recipientBalance (mul-up delta (get rate stream)))

        (senderBalance (- remainingBalance recipientBalance))

        (withdraw (* (get rate stream) (sub-up block-height (get startTime stream)))) 
        
        (bal {id: streamId, recipientBalance: recipientBalance, senderBalance: senderBalance, withdrawalAmount: recipientBalance, updated-at-block-height: block-height }))

        (map-set dynamic-balance (tuple (id streamId)) bal)
        (asserts! (>= (get deposit stream) remainingBalance) ERR_BALANCE_GREATER_DEPOSIT)
        (asserts! (is-eq who (get recipient stream)) (ok senderBalance))
        (asserts! (is-eq who (get sender stream)) (ok recipientBalance))
        (print {balance: bal})
       )
        (ok u0)
    )
 )

(define-public (withdraw-from-stream (streamId uint) (amount uint)) 
    (let (
        (stream (unwrap! (get-stream streamId) ERR_STREAM_NOT_FOUND))
        (delta (unwrap-panic (delta-of streamId)))
        (dynamic (unwrap-panic (get-dynamic-balance streamId)))
        (rate (get rate stream))
        (time (get startTime stream))
        (maxWithdraw (unwrap-panic (withdraw-amount rate time)))
        (deposit (get deposit stream))
        (recipient (get recipient stream))
        (remainingBalance (get remainingBalance stream))
        (recipientBalance (get recipientBalance dynamic))
        (senderBalance (- remainingBalance recipientBalance))) 
    (begin 
        (map-set Streams streamId (merge stream { remainingBalance: (- remainingBalance amount )}))
        (map-set dynamic-balance (tuple (id streamId)) (merge dynamic { withdrawalAmount: (- recipientBalance amount )}))
        (asserts! (unwrap-panic (stream-exist streamId)) ERR_STREAM_NOT_EXIST)
        (asserts! (> amount u0) ERR_AMOUNT_IS_ZERO)
        (asserts! (> recipientBalance amount) ERR_AMOUNT_EXCEEDS_BALANCE)
        (asserts! (unwrap-panic (is-sender-or-recipient streamId)) ERR_AMOUNT_IS_ZERO)
        (asserts! (>= maxWithdraw u0) ERR_AMOUNT_EXCEEDS_BALANCE)
        (asserts! (not (is-eq remainingBalance u0)) (ok (map-delete Streams streamId)))
        (asserts! (> (- remainingBalance amount) senderBalance) ERR_AMOUNT_EXCEEDS_BALANCE)
        (unwrap-panic (as-contract (contract-call? .cwe000-chain-btc transfer amount (as-contract tx-sender) recipient none)))
        (ok true)
    )
  )
)

(define-public (cancel-stream (streamId uint)) 
    (let (
      (stream (unwrap! (get-stream streamId) ERR_STREAM_NOT_FOUND))
      (recipient (get recipient stream))
      (sender (get sender stream))
      (senderBalance (unwrap-panic  (balance-of streamId sender)))
      (recipientBalance (unwrap-panic (balance-of streamId recipient)))) 

      (asserts! (unwrap-panic (stream-exist streamId)) ERR_STREAM_NOT_EXIST)
      (asserts! (or (is-eq contract-caller sender) (is-eq contract-caller recipient)) ERR_UNAUTHORIZED)
      (begin
         (map-delete Streams streamId)
         (asserts! (and (< recipientBalance u0) (> senderBalance u0)) 
         (ok (begin (try! (as-contract (contract-call? .cwe000-chain-btc transfer recipientBalance   (as-contract tx-sender) recipient none)))
         (try! (as-contract (contract-call? .cwe000-chain-btc transfer senderBalance   (as-contract tx-sender) sender none))))))
      )
        (ok true)
    )
)


(define-read-only (mul-up (a uint) (b uint))
    (let
        (
            (product (* a b))
       )
        (if (is-eq product u0)
            u0
            (+ u1 (/ (- product u1) ONE_8))
       )
   )
)
(define-constant ONE_8 u1) ;; 8 decimal places

(define-read-only (sub-up (a uint) (b uint))
    (let (
        (subtract (- a b))) 
        (if (<= subtract u0) u0 subtract)
   )
)

(define-read-only (div-up (a uint) (b uint))
    (if (is-eq a u0) u0 (+ u1 (/ (- (* a ONE_8) u1) b)))
)


(begin (create-stream 'ST3PF13W7Z0RRM42A8VZRVFQ75SV1K26RXEP8YGKJ u1000000 u0 u2000))

;; ::advance_chain_tip 1000
;; (contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.cwe001-chain-stream balance-of u1 tx-sender)
;; ::set_tx_sender ST3PF13W7Z0RRM42A8VZRVFQ75SV1K26RXEP8YGKJ
;; (contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.cwe001-chain-stream withdraw-from-stream u1 u100000)
;; ::get_assets_maps
;; (contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.cwe001-chain-stream get-stream u1)
;; (contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.cwe001-chain-stream withdraw-from-stream u1 u500000)
;; (contract-call? 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.cwe001-chain-stream create-stream-local-info u1)