;; Customer Experience Contract
;; Manages customer feedback and experiences

(define-constant ERR_INVALID_RATING (err u500))
(define-constant ERR_REVIEW_NOT_FOUND (err u501))
(define-constant ERR_UNAUTHORIZED (err u502))

;; Data maps
(define-map customer-reviews uint {
    customer: principal,
    restaurant-id: uint,
    food-rating: uint,
    service-rating: uint,
    ambiance-rating: uint,
    overall-rating: uint,
    review-text: (string-ascii 500),
    review-date: uint,
    verified: bool
})

(define-map customer-loyalty uint {
    customer: principal,
    restaurant-id: uint,
    visit-count: uint,
    total-spent: uint,
    loyalty-points: uint,
    tier: (string-ascii 20)
})

(define-data-var next-review-id uint u1)
(define-data-var next-loyalty-id uint u1)

;; Public functions
(define-public (submit-review
    (restaurant-id uint)
    (food-rating uint)
    (service-rating uint)
    (ambiance-rating uint)
    (review-text (string-ascii 500)))
    (let (
        (review-id (var-get next-review-id))
        (overall-rating (/ (+ food-rating service-rating ambiance-rating) u3))
    )
        (asserts! (and
            (<= food-rating u5) (>= food-rating u1)
            (<= service-rating u5) (>= service-rating u1)
            (<= ambiance-rating u5) (>= ambiance-rating u1)
        ) ERR_INVALID_RATING)
        (map-set customer-reviews review-id {
            customer: tx-sender,
            restaurant-id: restaurant-id,
            food-rating: food-rating,
            service-rating: service-rating,
            ambiance-rating: ambiance-rating,
            overall-rating: overall-rating,
            review-text: review-text,
            review-date: block-height,
            verified: false
        })
        (var-set next-review-id (+ review-id u1))
        (ok review-id)
    )
)

(define-public (update-loyalty-points
    (customer principal)
    (restaurant-id uint)
    (points-to-add uint)
    (amount-spent uint))
    (let ((loyalty-id (var-get next-loyalty-id)))
        (match (map-get? customer-loyalty restaurant-id)
            existing-loyalty (map-set customer-loyalty restaurant-id {
                customer: customer,
                restaurant-id: restaurant-id,
                visit-count: (+ (get visit-count existing-loyalty) u1),
                total-spent: (+ (get total-spent existing-loyalty) amount-spent),
                loyalty-points: (+ (get loyalty-points existing-loyalty) points-to-add),
                tier: (calculate-tier (+ (get loyalty-points existing-loyalty) points-to-add))
            })
            (map-set customer-loyalty restaurant-id {
                customer: customer,
                restaurant-id: restaurant-id,
                visit-count: u1,
                total-spent: amount-spent,
                loyalty-points: points-to-add,
                tier: (calculate-tier points-to-add)
            })
        )
        (ok true)
    )
)

;; Read-only functions
(define-read-only (get-review (review-id uint))
    (map-get? customer-reviews review-id)
)

(define-read-only (get-customer-loyalty (restaurant-id uint))
    (map-get? customer-loyalty restaurant-id)
)

(define-read-only (calculate-tier (points uint))
    (if (>= points u1000)
        "GOLD"
        (if (>= points u500)
            "SILVER"
            "BRONZE"
        )
    )
)

(define-read-only (get-average-rating (restaurant-id uint))
    ;; Simplified calculation - in practice would iterate through all reviews
    u4 ;; Placeholder return value
)
