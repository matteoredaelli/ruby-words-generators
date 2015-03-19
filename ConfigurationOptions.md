See http://code.google.com/p/ruby-words-generators/source/browse/trunk/settings.yaml.sample for a sample file

# WG #
## splitter\_options ##
## splitter\_key\_value ##

Separators inside config .yaml file
> splitter\_options: ","
> splitter\_key\_value: ":"

## dump\_results\_file ##
> dump\_results\_file: results.txt
# Wordlist #

## characters ##
```
 characters: "ab"
```
means that the words must be build with characters "a" and "b"

## min\_length ##
## max\_length ##
```
 min_length: 2
 max_length: 3
```
mean that the minimum length of words must be 2 and the maxminum 3

## min\_char\_occurs ##
## max\_char\_occurs ##

```
 max_char_occurs: ab:2
 min_char_occurs: b:1,a:1
```

The words must have <= 2 of "a" and "b", and >= 1 of "a" and "b". "ab:2" is equal to "a:2,b:2"

## min\_char\_list\_occurs ##
## max\_char\_list\_occurs ##

```
 min_char_list_occurs: 1234567890:1,ABCDEFG:1
 max_char_list_occurs: ABCDEF:2
```

The words must have at least 1 digit and an uppercase letter from A to G, and then at most 2 letters from A to F

## max\_consective\_chars ##

```
 max-consective_chars: 3
```

The words cannot have more than 3 identical consecutive chars

## max\_run\_iterations ##

```
 max_run_iterations: 10
```

The "run" action will stop after 10 iterations. then you can run it again. it is useful if you want to do some processing, stop them and then go on later (maybe the day after)

## prefix\_string ##
## postfix\_string ##

```
    prefix_string: astring
    postfix_string: astring2
```

You can add a string at the beginning and/or end of the generated words

## regexp\_list ##
Regular expressions evauated in the order: useful to exclude/include valid words
```
    regexp_list: |	 
      e,a$
      i,^a
```

The words must begin with "a" and NOT finish with a "a"