(local fu hs.fnutils)

;; Simple Utils
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(fn call-when
  [f]
  (when (and f (= (type f) :function))
    (f)))

(fn find
  [f tbl]
  (fu.find tbl f))

(fn get
  [prop-name tbl]
  (if tbl
      (. prop-name tbl)
      (fn [tbl]
        (. tbl prop-name))))

(fn has-some?
  [list]
  (and list (> (# list) 0)))

(fn join
  [sep list]
  (table.concat list sep))

(fn last
  [list]
  (. list (# list)))

(fn logf
  [...]
  (let [prefixes [...]]
    (fn [x]
      (print (table.unpack prefixes) (hs.inspect x)))))

(fn slice-start-end
  [start end list]
  (let [end (if (< end 0)
                (+ (# list) end)
                end)]
    (var sliced [])
    (for [i start end]
      (table.insert sliced (. list i)))
    sliced))

(fn slice-start
  [start list]
  (slice-start-end start (# list) list))

(fn slice
  [start end list]
  (if (and (= (type end) :table)
           (not list))
      (slice-start start end)
      (slice-start-end start end list)))

(fn split
  [search str]
  (fu.split str search))

(fn tap
  [f x ...]
  (f x (table.unpack [...]))
  x)


;; Reduce Primitives
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(fn seq?
  [tbl]
  (~= (. tbl 1) nil))

(fn seq
  [tbl]
  (if (seq? tbl)
    (ipairs tbl)
    (pairs tbl)))

(fn reduce
  [f acc tbl]
  (var result acc)
  (each [k v (seq tbl)]
    (set result (f result v k)))
  result)


;; Reducers
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(fn map
  [f tbl]
  (reduce
    (fn [new-tbl v k]
      (table.insert new-tbl (f v k))
      new-tbl)
    []
    tbl))

(fn merge
  [...]
  (let [tbls [...]]
    (reduce
     (fn merger [merged tbl]
       (each [k v (pairs tbl)]
         (tset merged k v))
       merged)
     {}
     tbls)))

(fn filter
 [f tbl]
 (reduce
  (fn [xs v k]
   (when (f v k)
    (table.insert xs v))
   xs)
  []
  tbl))

(fn concat
 [...]
 (reduce
  (fn [cat tbl]
    (each [_ v (ipairs tbl)]
      (table.insert cat v))
    cat)
  []
  [...]))


;; Exports
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

{:call-when call-when
 :concat    concat
 :filter    filter
 :get       get
 :find      find
 :has-some? has-some?
 :join      join
 :last      last
 :logf      logf
 :map       map
 :merge     merge
 :reduce    reduce
 :seq       seq
 :seq?      seq?
 :slice     slice
 :split     split
 :tap       tap}
