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

(fn find
 [f tbl]
 (do
   (var done? false)
   (var item nil)
   (var i 1)
   (while (and (not done?) (<= i (# tbl)))
     (let [v (. tbl i)]
       (when (f v)
         (set done? true)
         (set item v)))
     (set i (+ i 1)))
   item))

(fn join
  [sep list]
  (table.concat list sep))

(fn split
 [search str]
 (var pieces [])
 (var input str)
 (let [len (# search)]
   (while input
    (let [i (string.find input search 1 true)]
     (if i
       (let [left (string.sub input 1 (- i 1))
             right (string.sub input (+ i len))]
         (set input right)
         (table.insert pieces left))
       (do
         (table.insert pieces input)
         (set input nil))))))
 pieces)

(fn logf
 [...]
 (let [prefixes [...]]
  (fn [x]
   (print (table.unpack prefixes) (hs.inspect x)))))

(fn tap
 [f x ...]
 (f x (table.unpack [...]))
 x)

(fn concat
 [...]
 (reduce
  (fn [cat tbl]
    (each [_ v (ipairs tbl)]
      (table.insert cat v))
    cat)
  []
  [...]))

{
 :concat concat
 :filter filter
 :find find
 :join join
 :logf logf
 :map map
 :merge merge
 :reduce reduce
 :seq seq
 :seq? seq?
 :split split
 :tap tap
}
