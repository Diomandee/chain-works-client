(impl-trait .sip013-semi-fungible-token-trait.sip013-semi-fungible-token-trait)
(impl-trait .sip013-transfer-many-trait.sip013-transfer-many-trait)
(define-constant  ERR-NOT-AUTHORIZED u1403001)

(define-constant PERMISSION_DENIED_ERROR u400)
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-whitelisted (err u101))
(define-constant err-insufficient-balance (err u1))
(define-constant err-invalid-sender (err u4))
(define-map token-balances {token-id: uint, owner: principal} uint)
(define-map token-supplies uint uint)
(define-map token-decimals uint uint)
(define-map asset-contract-ids principal uint)
(define-map asset-contract-whitelist principal bool)
(define-data-var asset-contract-id-nonce uint u0)
(define-data-var deployer-principal principal tx-sender)
(define-data-var is-initialized bool false)


(define-map allowances {spender: principal, owner: principal} {allowance: uint})
(define-fungible-token chain-stx)
(define-non-fungible-token chain-parent {token-id: uint, owner: principal})

;; ------------------------------------------
;; Variables
;; ------------------------------------------

(define-private (set-balance (token-id uint) (balance uint) (owner principal))
	(map-set token-balances {token-id: token-id, owner: owner} balance)
)

(define-private (get-balance-uint (token-id uint) (who principal))
	(default-to u0 (map-get? token-balances {token-id: token-id, owner: who}))
)

(define-read-only (get-balance (token-id uint) (who principal))
	(ok (get-balance-uint token-id who))
)

(define-read-only (get-overall-balance (who principal))
	(ok (ft-get-balance chain-stx who))
)

(define-read-only (get-total-supply (token-id uint))
	(ok (default-to u0 (map-get? token-supplies token-id)))
)

(define-read-only (get-overall-supply)
	(ok (ft-get-supply chain-stx))
)

(define-read-only (get-decimals (token-id uint))
	(ok (default-to u0 (map-get? token-decimals token-id)))
)

(define-read-only (get-token-uri (token-id uint))
	(ok none)
)

(define-public (transfer (token-id uint) (amount uint) (sender principal) (recipient principal))
	(let
		(
			(sender-balance (get-balance-uint token-id sender))
		)
		(asserts! (or (is-eq sender tx-sender) (is-eq sender contract-caller)) err-invalid-sender)
		(asserts! (<= amount sender-balance) err-insufficient-balance)
		(try! (ft-transfer? chain-stx amount sender recipient))
		(try! (tag-nft-token-id {token-id: token-id, owner: sender}))
		(try! (tag-nft-token-id {token-id: token-id, owner: recipient}))
		(set-balance token-id (- sender-balance amount) sender)
		(set-balance token-id (+ (get-balance-uint token-id recipient) amount) recipient)
		(print {type: "sft_transfer", token-id: token-id, amount: amount, sender: sender, recipient: recipient})
		(ok true)
	)
)

(define-public (transfer-memo (token-id uint) (amount uint) (sender principal) (recipient principal) (memo (buff 34)))
	(begin
		(try! (transfer token-id amount sender recipient))
		(print memo)
		(ok true)
	)
)

(define-private (transfer-many-iter (item {token-id: uint, amount: uint, sender: principal, recipient: principal}) (previous-response (response bool uint)))
	(match previous-response prev-ok (transfer (get token-id item) (get amount item) (get sender item) (get recipient item)) prev-err previous-response)
)

(define-public (transfer-many (transfers (list 200 {token-id: uint, amount: uint, sender: principal, recipient: principal})))
	(fold transfer-many-iter transfers (ok true))
)

(define-private (transfer-many-memo-iter (item {token-id: uint, amount: uint, sender: principal, recipient: principal, memo: (buff 34)}) (previous-response (response bool uint)))
	(match previous-response prev-ok (transfer-memo (get token-id item) (get amount item) (get sender item) (get recipient item) (get memo item)) prev-err previous-response)
)

(define-public (transfer-many-memo (transfers (list 200 {token-id: uint, amount: uint, sender: principal, recipient: principal, memo: (buff 34)})))
	(fold transfer-many-memo-iter transfers (ok true)))




(define-public (stream-to (token-id uint) (amount uint) (sender principal) (recipient principal))
	(let
		(
			(sender-balance (get-balance-uint token-id sender))
		)
		(asserts! (<= amount sender-balance) err-insufficient-balance)
		(try! (ft-transfer? chain-stx amount sender recipient))
		(set-balance token-id (- sender-balance amount) sender)
		(set-balance token-id (+ (get-balance-uint token-id recipient) amount) recipient)
		(print {type: "sft_transfer", token-id: token-id, amount: amount, sender: sender, recipient: recipient})
		(ok true)
	)
)

(define-private (stream-many-iter (item {token-id: uint, amount: uint, sender: principal, recipient: principal}) (previous-response (response bool uint)))
	(match previous-response prev-ok (stream-to (get token-id item) (get amount item) (get sender item) (get recipient item)) prev-err previous-response)
)
(define-public (stream-many (stream (list 200 {token-id: uint, amount: uint, sender: principal, recipient: principal})))
	(fold stream-many-iter stream (ok true))
)
(define-public (transfer-stream-memo (token-id uint) (amount uint) (sender principal) (recipient principal) (memo (buff 34)))
	(begin
		(try! (transfer token-id amount sender recipient))
		(print memo)
		(ok true)
	)
)

;; Wrapping and unwrapping logic



;; ---------------------------------------------------------
;; Wrap / Unwrap
;; ---------------------------------------------------------
(define-public (wrap (amount uint) (recipent principal))
  (begin
    (try! (stx-transfer? amount tx-sender .chain-manager))
    (ft-mint? chain-stx amount recipent)
  )
)

(define-public (unwrap (amount uint))
  (let (
    (recipient tx-sender)
  )
    ;; (try! (as-contract (stx-transfer? amount (as-contract tx-sender) recipient)))
    (ft-burn? chain-stx amount recipient)
  )
)






(define-public (transfer-ft (amount uint) (sender principal) (recipient principal) (memo (optional (buff 34))))
  (begin
    (asserts! (is-eq tx-sender sender) (err  ERR-NOT-AUTHORIZED))

    (match (ft-transfer? chain-stx amount sender recipient)
      response (begin
        (print memo)
        (ok response)
      )
      error (err error)
    )
  )
)
;; Authorize
;; ---------------------------------------------------------

(define-private (transfer-to (amount uint) (sender principal) (recipient principal) )
  (match (ft-transfer? chain-stx amount sender recipient)
    result (ok true)
    error (err false))
)


;; Gets the amount of tokens that an owner allowed to a spender.
(define-private (allowance-of (owner principal) (spender principal))
  (begin
  (default-to u0
    (get allowance
       (map-get? allowances {spender: spender, owner: owner}))))
)

;; Decrease allowance of a specified spender.
(define-private (decrease-allowance (amount uint) (spender principal) (owner principal))
  (let (
      (allowance (allowance-of spender owner)))
    (if (or (> amount allowance) (<= amount u0))
      true
      (begin
        (map-set allowances
          {spender: spender, owner: owner}
          {allowance: (- allowance amount)})
        true))))

;; Internal - Increase allowance of a specified spender.
(define-private (increase-allowance (amount uint) (spender principal) (owner principal))
  (let ((allowance (allowance-of spender owner)))
    (if (<= amount u0)
      false
      (begin
         (map-set allowances
          {spender: spender, owner: owner}
          {allowance: (+ allowance amount)})
        true))))

;; Public functions


;; Transfers tokens to a specified principal, performed by a spender
(define-public (transfer-from (amount uint) (owner principal) (recipient principal) )
  (let ((allowance (allowance-of tx-sender owner)))
    (begin
      (if (or (> amount allowance) (<= amount u0))
        (err false)
        (if (and
            (unwrap! (transfer-to amount owner recipient) (err false))
            (decrease-allowance amount tx-sender owner))
        (ok true)
        (err false)))))
)

;; Update the allowance for a given spender
(define-public (approve (amount uint) (spender principal) )
  (if (and (> amount u0)
           (print (increase-allowance amount spender tx-sender )))
      (ok amount)
      (err false)))

;; Revoke a given spender
(define-public (revoke (spender principal))
  (let ((allowance (allowance-of spender tx-sender)))
    (if (and (> allowance u0)
             (decrease-allowance allowance spender tx-sender))
        (ok 0)
        (err false))))

(define-public (balance-of (owner principal))
  (begin
      (print owner)
      (ok (ft-get-balance chain-stx owner))
  )
)


;; Initialization
;; --------------------------------------------------------------------------

(define-public (tag-nft-token-id-transfer (recipients principal) (nft-token-id {token-id: uint, owner: principal}))
	(begin
			(try! (nft-transfer? chain-parent nft-token-id (get owner nft-token-id) recipients))
      (ok true)
	)
)



(define-public (callback (sender principal) (memo (buff 34)))
	(ok true)
)

(define-private (stx-mint-many-iter (item {amount: uint, recipient: principal}))

	(ft-mint? chain-stx (get amount item) (get recipient item))
  
)

(define-public (stx-mint-many (recipients (list 200 {amount: uint, recipient: principal})))
	(begin
  
		(ok (map stx-mint-many-iter recipients))
	)
)

;; Wrapping and unwrapping logic

(define-read-only (get-asset-token-id (asset-contract principal))
	(map-get? asset-contract-ids asset-contract)
)

(define-public (get-or-create-asset-token-id (sip010-asset principal))
	(match (get-asset-token-id  sip010-asset)
		token-id (ok token-id)
		(let
			(
				(token-id (+ (var-get asset-contract-id-nonce) u1))
			)
			(asserts! (is-whitelisted .chain-stx) err-not-whitelisted)
			(map-set asset-contract-ids .chain-stx token-id)
			(var-set asset-contract-id-nonce token-id)
			(ok token-id)
		)
	)
)
(define-read-only (get-owner (token-id uint) (owner principal))
  (ok (nft-get-owner? chain-parent {token-id: token-id, owner: owner})))

(define-public (mint (amount uint) (token-id uint) (owner principal))
	(begin
		(try! (ft-mint? chain-stx amount owner))
		(try! (tag-nft-token-id {token-id: token-id, owner: owner}))
		(set-balance token-id (+ (get-balance-uint token-id owner) amount) owner)
		(map-set token-supplies token-id (+ (unwrap-panic (get-total-supply token-id)) amount))
		(print {type: "sft_mint", token-id: token-id, amount: amount, recipient: owner})
		(ok token-id)
	)
)

(define-public (burn (amount uint) (recipient principal) (sip010-asset principal))
	(let
		(
			(token-id (try! (get-or-create-asset-token-id sip010-asset)))
			(original-sender tx-sender)
			(sender-balance (get-balance-uint token-id tx-sender))
		)
		(asserts! (<= amount sender-balance) err-insufficient-balance)
		(try! (ft-burn? chain-stx amount original-sender))
		(set-balance token-id (- sender-balance amount) original-sender)
		(map-set token-supplies token-id (- (unwrap-panic (get-total-supply token-id)) amount))
		(print {type: "sft_burn", token-id: token-id, amount: amount, sender: original-sender})
		(ok token-id)
	)
)

(define-private (tag-nft-token-id (nft-token-id {token-id: uint, owner: principal}))
	(begin
		(and
			(is-some (nft-get-owner? chain-parent nft-token-id))
			(try! (nft-burn? chain-parent nft-token-id (get owner nft-token-id)))
		)
		(nft-mint? chain-parent nft-token-id (get owner nft-token-id))
	)
)

(define-read-only (is-whitelisted (asset-contract principal))
	(default-to false (map-get? asset-contract-whitelist asset-contract))
)

(define-public (set-whitelisted (asset-contract principal) (whitelisted bool))
	(begin
		(asserts! (is-eq contract-owner tx-sender) err-owner-only)
		(ok (map-set asset-contract-whitelist asset-contract whitelisted))
	)
)

(begin (set-whitelisted .chain-stx true))
;; (begin (get-or-create-asset-token-id .chain-stx))

