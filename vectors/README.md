# Vector Learning

Vectors are an essential type in Clash. They are similar to lists in Haskell
(kind of) and the are similar to Arrays in Verilog (kind of).

It's convenient at times to think of data a `Unsigned N` values (where N is the
number of bits). Sometimes we need to get AT the values of the bits and do stuff
to them. There are two types of vectors: `Vec` and `BitVector`. `BitVector` is
really what we wanna talk about here - it allows us to convert values from
numbers to an list of bits. 

`Vec` is used for pretty much everything else.

## Links

- [Vec Documentation](https://hackage.haskell.org/package/clash-prelude-1.8.1/docs/Clash-Prelude.html#g:20)
- [BitVector Documentation](https://hackage.haskell.org/package/clash-prelude-1.8.1/docs/Clash-Sized-BitVector.html)
- [BitPack Documentation](https://hackage.haskell.org/package/clash-prelude-1.8.1/docs/Clash-Class-BitPack.html)
- [Resize Documentation](https://hackage.haskell.org/package/clash-prelude-1.8.1/docs/Clash-Class-Resize.html)
- [Index Documentation](https://hackage.haskell.org/package/clash-prelude-1.8.1/docs/Clash-Sized-Index.html#t:Index)

## `Vec` (from Clash Documentation)

Fixed size vectors.

-   Lists with their length encoded in their type
-   Vector elements have an ASCENDING subscript starting from 0 and ending at length - 1.

## `BitVector` (from Clash Documentation)

A vector of bits:

-   Bit indices are descending
-   Num instance performs unsigned arithmetic.

NB: The usual Haskell method of converting an integral numeric type to another,
fromIntegral, is not well suited for Clash as it will go through Integer which
is arbitrarily bounded in HDL. Instead use bitCoerce and the Resize class.

BitVector has the type role:

``` haskell
>>> :i BitVector
type role BitVector nominal
...
````

as it is not safe to coerce between different sizes of BitVector. To change the
size, use the functions in the Resize class.

### Using BitVector

Converting an `Unsigned` value to a `BitVector` one is pretty easy using the
`pack` function from the `BitPack` type class:

``` haskell
clashi> let x = 1 :: Unsigned 8
clashi> pack x
0b0000_0001
clashi> :t pack x
pack x :: BitVector 8
```

Super simple! Going the other way is pretty easy too, using the `unpack`
function (also from `BitPack`):

``` haskell
clashi> let y = pack x
clashi> unpack y :: Unsigned 8
1
clashi> :t (unpack y :: Unsigned 8)
(unpack y :: Unsigned 8) :: Unsigned 8
```

The best way to construct a `BitVector` that I know is to use convert an
`Unsigned` value into a `BitVector`

## `BitVector` "Methods" 

For these examples let's use the following definitions:

``` haskell
clashi> let x = pack (1 :: Unsigned 8)
clashi> let y = pack (2 :: Unsigned 8)
clashi> let z = pack (3 :: Unsigned 8)
```

### AND

``` haskell
> x .&. x
0b0000_0001
> x .&. y
0b0000_0000
> x .&. z
0b0000_0001
```

### OR

``` haskell
> x .|. y
0b0000_0011
```

### XOR

``` haskell
> x `xor` y
0b0000_0011
> x `xor` z
0b0000_0010
```

### complement

``` haskell
> complement x
0b1111_1110
```

### left shift

``` haskell
> shiftL x 0
0b0000_0001
> shiftL x 1
0b0000_0010
> shiftL x 2
0b0000_0100
```

### Other functions that would be useful to know about

- `shiftL`
- `shiftR`
- `setBit`
- `clearBit`
- `complementBit`
- `zeroBits`
- `rotateL`
- `rotateR`
- `isSigned`

### Semi related: Split an `Unsigned` value into `BitVectors`

What's neat about this is that the split is dictated by the desired type.

``` haskell
clashi> let xx = split (1 :: Unsigned 8) :: (BitVector 4, BitVector 4)
clashi> xx
(0b0000,0b0001)
```

# `BitPack` and Other cool stuff

Now that we know that `BitPack` exists, what does it mean about values that
derive from it?

We can convert from a Signed value to an Unsigned value to another using
`bitCoerce`:

``` haskell
clashi> let x = 10 :: Signed 8
clashi> x
10
clashi> let y = bitCoerce x :: Unsigned 8
clashi> y
10
clashi> :t y
y :: Unsigned 8
```

## Other neat stuff

Things that derive from `BitPack` can use these functions.

### Indexing (`!`)

``` haskell
> let x = 10 :: Signed 10
> x ! 0
0
> x ! 1
1
```

### MSB

``` haskell
> let x = (-10) :: Signed 10
> msb x
1
```

### LSB

``` haskell
> let x = 1 :: Unsigned 8
> lsb x
1
```

# What about Converting between Things of different sizes?

For this we use the `Resize` functions. There are a few here:

- `resize`
- `extend` (`zeroExtend`, `signExtend`)
- `truncateB`

`BitVector`, `Signed`, and `Unsigned` all derive this type class. For most
cases, `resize` should "Just Work".

## `Resize.resize` Documentation

A sign-preserving resize operation:

- For signed datatypes: Increasing the size of the number replicates the sign
  bit to the left. Truncating a number to length L keeps the sign bit and the
  rightmost L-1 bits.

- For unsigned datatypes: Increasing the size of the number extends with zeros
  to the left. Truncating a number of length N to a length L just removes the
  left (most significant) N-L bits.

## Note: Resize Just Does it

`resize` will just "lop" off bits without a warning:

``` haskell
clashi> let x = 10 :: Unsigned 8
clashi> let y = resize x :: Unsigned 4
clashi> y
10
clashi> let z = resize x :: Unsigned 3
clashi> z
2
```

# WHEN DO WE GET TO VECTORS

I've spent quite a lot of time talking about Unsigned numbers... which are not
Vectors. So let's talk about Vectors. Vectors are a fixed length "list" like
structure. 

What's cool about the Vector type constructor `Vec` is that it's a Data Kind I
think:

``` haskell
> :k Vec
Vec :: Nat -> Type -> Type
```

------

What is a `Type`?

``` haskell
> :doc Type
Type :: Type    -- Type constructor defined in ‘GHC.
Types’
-- | The kind of types with lifted values. For examp
le @Int :: Type@.
```

Oh it's just a GHC Type thing. OK So Type is just a "Type". Neat. 

------

So our `Vec` can be anything, that's cool.

## Conversion from BitVector

We can define a `Vector` of `Bit` values to make a "Vector of Bits":

``` haskell
> let x = 0 :> 1 :> 0 :> 1 :> Nil :: Vec 4 Bit
> :t x 
x :: Num a => Vec 4 Bit
```

We can convert this into a `BitVector` using `v2bv` (aka vector 2 bitVector)

``` haskell
> v2bv x
0b0101
```

Super cool!

## Vector of Indices

We can create a vector of values up to (but not including) a specified value
using the `indices` Vector function:

``` haskell
clashi> :t indices
indices :: KnownNat n => SNat n -> Vec n (Index n)
clashi> indices (SNat @4)
0 :> 1 :> 2 :> 3 :> Nil
```

We can also generate the indices based on Types (if you're using the Index
Type):

``` haskell
clashi> indicesI :: Vec 4 (Index 4)
0 :> 1 :> 2 :> 3 :> Nil
```

------

Dear god what is an Index? From the documentation it's an "Arbitrarily-bounded
unsigned integer represented by `ceil(log_2(n))` bits. Given an upper bound `n`,
an `Index n` number has a range of: `[0..n-1]`

So in short: It's a special `Unsigned` integer. 

------

## Other Vector Things

So what else is there? SO MUCH MORE. Here's some highlights:

- `(!!)`
- `head`
- `last`
- `at`
- `findIndex`
- `elemIndex`
- `take`
- `drop`

But Vector is SO COOL. I'll make notes here as I use vectors with examples.
