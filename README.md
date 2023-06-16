# Run Fennel on Norns

The [Norns sound computer](https://github.com/monome/norns/) is a Lua-scriptable device that uses SuperCollider under the hood.

Some folks [have been curious](https://llllllll.co/t/fennel-lua-compatible-lisp-on-norns/) as to whether one could write scripts in [Fennel](https://fennel-lang.org/) instead of Lua. Where Fennel is a functional programming language that is amenable to REPL-driven development.

This project is an example of how to communicate to Norns via Fennel, both via a REPL and at the entire script level.

## TL;DR

### Script setup
- ssh into your norns
- `cd dust/code`
- `git clone https://github.com/philomates/fennel-on-norns`
- `make funcho`
- run the script on Norns

### Text-editor setup

- Install NeoVim and the Conjure REPL plugin.
- [patch your local Conjure install directory with these changes](https://github.com/Olical/conjure/commit/8a759016ef60890db4a9f94ef38ec8af727fb490) and run `make compile` in that directory
- Use the following vimscript configuration for Conjure, where the IP in `ws://192.168.178.114:5555` points to your Norns
```vimscript
let g:conjure#filetype#fennel = "conjure.client.fennel.stdio"
let g:conjure#client#fennel#stdio#format = "eval_base64(\"%s\")"
let g:conjure#client#fennel#stdio#compile = 1
let g:conjure#client#fennel#stdio#command = "fennel"
let g:conjure#client#fennel#stdio#encoding = "base64"
let g:conjure#client#fennel#stdio#command = "websocat --protocol bus.sp.nanomsg.org ws://192.168.178.114:5555"
let g:conjure#client#fennel#stdio#prompt_pattern = "\n"
```
- Open Fennel file with NeoVim and start sending forms to the REPL!

## The idea

Fennel compiles to Lua, so there are several potential ways to adapt the system to accept Fennel.

I wanted an approach that required little or no modification to the Norns codebase itself.

The approach I took was 2-fold:
 - For a Norns script: write it in Fennel and then compile it to Lua by ssh-ing into the machine and run `make`.
 - For REPL interaction from your text editor: tweak the text editor's REPL plugin to call the Fennel-to-Lua compiler on the code form you want to send to the Norns.

### Compiling Fennel scripts to Lua

There is an example norns script in this repository called `funcho.fnl` ("fennel" in portuguese)

It must be compiled to Lua in order to be loaded by the Norns:
This can be done with the following command (which can be invoked via `make funcho`):

```bash
./fennel --compile --require-as-include funcho.fnl > funcho.lua
```

From there the `funcho.lua` script can be loaded via Norns normally.

The `--require-as-include` flag will take all other Fennel files that are required by the script, compile them, and include them in the final `funcho.lua` script.

### Send Fennel to the Norns REPL

Using a REPL, one can send code forms from a local text editor over the network to your Norns. This allows you to modify and develop scripts in an interactive way from the comfort of your preferred text editor.

To get Fennel working, you'll need to shim into your text editor's REPL client and call the Fennel compiler on the code form before sending it to the Norns. I was able to quickly do this for NeoVim and the [Conjure REPL client](https://github.com/Olical/conjure/), given that Conjure is written in Fennel and exposes the Fennel compiler. That said, I'm not sure how tenable this is in most editors.

I created my own fork of Conjure and added a configuration that runs the Fennel-to-Lua compiler on forms before sending them to the server (the Norns). If you want to use NeoVim + Conjure, you'll need to [apply these changes to your local Conjure install](https://github.com/Olical/conjure/commit/8a759016ef60890db4a9f94ef38ec8af727fb490) and then run `make compile` in that directory. With them in place you can set the Conjure configuration to

```fennel
(set nvim.g.conjure#filetype#fennel "conjure.client.fennel.stdio")

;; where 192.168.178.114 is replaced with the IP of your Norns
(set nvim.g.conjure#client#fennel#stdio#command "websocat --protocol bus.sp.nanomsg.org ws://192.168.178.114:5555")
(set nvim.g.conjure#client#fennel#stdio#prompt_pattern "\n")

;; This is the new configuration I added that, when set, compiles the form from Fennel to Lua before sending it
(set nvim.g.conjure#client#fennel#stdio#compile true)
```

With this in place, when you send `(fn inc [x] (+ 1 x))` to the REPL, it gets compiled to `local function inc(x) return (1 + x) end` and then sent to the Norns.


#### Sending multi-line forms over the REPL

My first attempt to solve this problem was actually going off of a different approach of running the Fennel compiler on the Norns itself, as achieved by [the `orbit_normal` user on lines](https://llllllll.co/t/fennel-lua-compatible-lisp-on-norns/35977). This worked but was limited by the fact that the websocket REPL could only accept one-line REPL messages. This works with Lua because the Lua interpreter keeps track of when you are in the middle of a multi-line form and responds with `<incomplete>`.

To avoid dealing with any potential multi-line issues, I first base64 encode the code form to get rid of line-breaks and then send it across wrapped in a Lua function that decodes the base64 string and evaluates it.

So `local function inc(x) return (1 + x) end` gets turned into and then sent to the Norns:
```
eval_base64("bG9jYWwgZnVuY3Rpb24gaW5jKHgpIF9fX3JlcGxMb2NhbHNfX19bJ18yYW1vZHVsZV9uYW1lXzJhJ10gPSBfMmFtb2R1bGVfbmFtZV8yYSBfX19yZXBsTG9jYWxzX19fWydkZWNvZGUnXSA9IGRlY29kZSBfX19yZXBsTG9jYWxzX19fWydlbmNvZGUnXSA9IGVuY29kZSBfX19yZXBsTG9jYWxzX19fWydfMmFtb2R1bGVfMmEnXSA9IF8yYW1vZHVsZV8yYSBfX19yZXBsTG9jYWxzX19fWydiJ10gPSBiIF9fX3JlcGxMb2NhbHNfX19bJ18yYWZpbGVfMmEnXSA9IF8yYWZpbGVfMmEgX19fcmVwbExvY2Fsc19fX1snXzJhbW9kdWxlX2xvY2Fsc18yYSddID0gXzJhbW9kdWxlX2xvY2Fsc18yYSByZXR1cm4gKDEgKyB4KSBlbmQ=")
```

Where `eval_base64` is specified in a lib of the Norns script as:

```fennel
(set b64 (require :lib.base64))

(global eval_base64 (fn [base64_str]
  (let [expr_str (b64.decode base64_str)]
    ((load expr_str)))))
```

and can then be loaded in the main script via a `(require :lib.shim)` line.

We then need to configure Conjure to base64 encode the form before passing it over, and also wrap the base64 string in a `eval_base64` call:

```fennel
(set nvim.g.conjure#client#fennel#stdio#format "eval_base64(\"%s\")")
(set nvim.g.conjure#client#fennel#stdio#encoding "base64")
```

The base64 isn't strictly necessary but I think if you want pretty-printing, as described below, you need it

#### Pretty-printing results from the REPL

One draw-back of the approach of compiling Fennel to Lua and sending it to the Norns is that you get Lua values as responses. For a Fennel list like `[1 2 3]`, you will get back `table: 0xe20f10` in the REPL console. This `table: ...` opacity in the console always tripped me up when working with Lua. So if we want to get Fennel results back, we need to add a shim on the server-side, similar to the `eval_base64` above that calls the Fennel pretty-printer on the result before passing it back.

```fennel
(set view (require :lib.view)) ;; the pretty-printer from the Fennel compiler
(set b64 (require :lib.base64))

(global eval_base64 (fn [base64_str]
  (let [expr_str (b64.decode base64_str)]
    (view ((load expr_str))))))
```

## current issues and stumbling blocks

### locals vs globals

When interacting with the Lua repl, you'll probably have issues accessing the locals of your Norns script. This applies also to Fennel, so if you are getting reference issues, try changing from locals to globals.

### issues installing the eval/base64-decode/pretty-print shim

The second time I load the `funcho` script, the `eval_base64` shim doesn't seem to get registered. The only way I've found to get it to work is to restart matron: `systemctl restart "norns-matron.service"`

My (shot in the dark) hunch is it has to due with the usage of the `--require-as-include` Fennel compiler flag, which emits `package.preload` Lua forms that maybe have weird caching/reloading behavior(?)
