module Test1
    using Automa
    using Base.Test

    re = re""

    re.actions[:enter] = [:enter_re]
    re.actions[:exit] = [:exit_re]

    machine = compile(re)
    init_code = generate_init_code(machine)
    exec_code = generate_exec_code(machine, actions=:debug)

    @eval function validate(data)
        logger = Symbol[]
        $(init_code)
        p_end = p_eof = endof(data)
        $(exec_code)
        return cs ∈ $(machine.final_states), logger
    end

    @test validate(b"") == (true, [:enter_re, :exit_re])
    @test validate(b"a") == (false, Symbol[])

    # inlined code
    exec_code = generate_exec_code(machine, actions=:debug, code=:inline)
    @eval function validate2(data)
        logger = Symbol[]
        $(init_code)
        p_end = p_eof = endof(data)
        $(exec_code)
        return cs ∈ $(machine.final_states), logger
    end
    @test validate2(b"") == (true, [:enter_re, :exit_re])
    @test validate2(b"a") == (false, Symbol[])
end

module Test2
    using Automa
    using Base.Test
    const re = Automa.RegExp

    a = re.rep(re"a")
    b = re.cat(re"b", re.rep(re"b"))
    ab = re.cat(a, b)

    a.actions[:enter] = [:enter_a]
    a.actions[:exit] = [:exit_a]
    b.actions[:enter] = [:enter_b]
    b.actions[:exit] = [:exit_b]
    ab.actions[:enter] = [:enter_re]
    ab.actions[:exit] = [:exit_re]

    machine = compile(ab)
    init_code = generate_init_code(machine)
    exec_code = generate_exec_code(machine, actions=:debug)

    @eval function validate(data)
        logger = Symbol[]
        $(init_code)
        p_end = p_eof = endof(data)
        $(exec_code)
        return cs ∈ $(machine.final_states), logger
    end

    @test validate(b"b") == (true, [:enter_re,:enter_a,:exit_a,:enter_b,:exit_re,:exit_b])
    @test validate(b"a") == (false, [:enter_re,:enter_a])
    @test validate(b"ab") == (true, [:enter_re,:enter_a,:exit_a,:enter_b,:exit_re,:exit_b])
    @test validate(b"abb") == (true, [:enter_re,:enter_a,:exit_a,:enter_b,:exit_re,:exit_b])

    # inlined code
    exec_code = generate_exec_code(machine, actions=:debug, code=:inline)
    @eval function validate2(data)
        logger = Symbol[]
        $(init_code)
        p_end = p_eof = endof(data)
        $(exec_code)
        return cs ∈ $(machine.final_states), logger
    end
    @test validate2(b"b") == (true, [:enter_re,:enter_a,:exit_a,:enter_b,:exit_re,:exit_b])
    @test validate2(b"a") == (false, [:enter_re,:enter_a])
    @test validate2(b"ab") == (true, [:enter_re,:enter_a,:exit_a,:enter_b,:exit_re,:exit_b])
    @test validate2(b"abb") == (true, [:enter_re,:enter_a,:exit_a,:enter_b,:exit_re,:exit_b])
end

module Test3
    using Automa
    using Base.Test
    const re = Automa.RegExp

    header = re"[ -~]*"
    newline = re"\r?\n"
    sequence = re.rep(re.cat(re"[A-Za-z]*", newline))
    fasta = re.rep(re.cat(re">", header, newline, sequence))

    machine = compile(fasta)
    init_code = generate_init_code(machine)
    exec_code = generate_exec_code(machine)

    @eval function validate(data)
        $(init_code)
        p_end = p_eof = endof(data)
        $(exec_code)
        return cs ∈ $(machine.final_states)
    end

    @test validate(b"") == true
    @test validate(b">\naa\n") == true
    @test validate(b">seq1\n") == true
    @test validate(b">seq1\na\n") == true
    @test validate(b">seq1\nac\ngt\n") == true
    @test validate(b">seq1\r\nacgt\r\n") == true
    @test validate(b">seq1\nac\n>seq2\ngt\n") == true
    @test validate(b"a") == false
    @test validate(b">") == false
    @test validate(b">seq1\na") == false
    @test validate(b">seq1\nac\ngt") == false

    exec_code = generate_exec_code(machine, code=:inline)
    @eval function validate2(data)
        $(init_code)
        p_end = p_eof = endof(data)
        $(exec_code)
        return cs ∈ $(machine.final_states)
    end
    @test validate2(b"") == true
    @test validate2(b">\naa\n") == true
    @test validate2(b">seq1\n") == true
    @test validate2(b">seq1\na\n") == true
    @test validate2(b">seq1\nac\ngt\n") == true
    @test validate2(b">seq1\r\nacgt\r\n") == true
    @test validate2(b">seq1\nac\n>seq2\ngt\n") == true
    @test validate2(b"a") == false
    @test validate2(b">") == false
    @test validate2(b">seq1\na") == false
    @test validate2(b">seq1\nac\ngt") == false
end

module Test4
    using Automa
    using Base.Test
    const re = Automa.RegExp

    beg_a = re.cat(re"a", re"[ab]*")
    end_b = re.cat(re"[ab]*", re"b")
    beg_a_end_b = re.isec(beg_a, end_b)

    machine = compile(beg_a_end_b)
    init_code = generate_init_code(machine)
    exec_code = generate_exec_code(machine)

    @eval function validate(data)
        $(init_code)
        p_end = p_eof = endof(data)
        $(exec_code)
        return cs ∈ $(machine.final_states)
    end

    @test validate(b"") == false
    @test validate(b"a") == false
    @test validate(b"aab") == true
    @test validate(b"ab") == true
    @test validate(b"aba") == false
    @test validate(b"abab") == true
    @test validate(b"abb") == true
    @test validate(b"abbb") == true
    @test validate(b"b") == false
    @test validate(b"bab") == false

    exec_code = generate_exec_code(machine, code=:inline)
    @eval function validate2(data)
        $(init_code)
        p_end = p_eof = endof(data)
        $(exec_code)
        return cs ∈ $(machine.final_states)
    end
    @test validate2(b"") == false
    @test validate2(b"a") == false
    @test validate2(b"aab") == true
    @test validate2(b"ab") == true
    @test validate2(b"aba") == false
    @test validate2(b"abab") == true
    @test validate2(b"abb") == true
    @test validate2(b"abbb") == true
    @test validate2(b"b") == false
    @test validate2(b"bab") == false
end

module Test5
    using Automa
    using Base.Test
    const re = Automa.RegExp

    keyword = re.alt(re"if", re"else", re"end", re"while")
    ident = re.diff(re"[a-z]+", keyword)
    token = re.alt(keyword, ident)

    keyword.actions[:exit] = [:keyword]
    ident.actions[:exit] = [:ident]

    machine = compile(token)
    init_code = generate_init_code(machine)
    exec_code = generate_exec_code(machine, actions=:debug)

    @eval function validate(data)
        logger = Symbol[]
        $(init_code)
        p_end = p_eof = endof(data)
        $(exec_code)
        return cs ∈ $(machine.final_states), logger
    end

    @test validate(b"if") == (true, [:keyword])
    @test validate(b"else") == (true, [:keyword])
    @test validate(b"end") == (true, [:keyword])
    @test validate(b"while") == (true, [:keyword])
    @test validate(b"e") == (true, [:ident])
    @test validate(b"eif") == (true, [:ident])
    @test validate(b"i") == (true, [:ident])
    @test validate(b"iff") == (true, [:ident])
    @test validate(b"1if") == (false, [])

    exec_code = generate_exec_code(machine, actions=:debug, code=:inline)
    @eval function validate2(data)
        logger = Symbol[]
        $(init_code)
        p_end = p_eof = endof(data)
        $(exec_code)
        return cs ∈ $(machine.final_states), logger
    end
    @test validate2(b"if") == (true, [:keyword])
    @test validate2(b"else") == (true, [:keyword])
    @test validate2(b"end") == (true, [:keyword])
    @test validate2(b"while") == (true, [:keyword])
    @test validate2(b"e") == (true, [:ident])
    @test validate2(b"eif") == (true, [:ident])
    @test validate2(b"i") == (true, [:ident])
    @test validate2(b"iff") == (true, [:ident])
    @test validate2(b"1if") == (false, [])
end

module Test6
    using Automa
    using Base.Test
    const re = Automa.RegExp

    foo = re"foo"
    foos = re.rep(re.cat(foo, re" *"))
    foo.actions[:exit]  = [:foo]
    actions = Dict(:foo => :(push!(ret, state.p:p-1); @escape))
    machine = compile(foos)

    @eval type MachineState
        p::Int
        cs::Int
        function MachineState()
            $(generate_init_code(machine))
            return new(p, cs)
        end
    end

    @eval function run!(state, data)
        ret = []
        p = state.p
        cs = state.cs
        p_end = p_eof = endof(data)
        $(generate_exec_code(machine, actions=actions))
        state.p = p
        state.cs = cs
        return ret
    end

    state = MachineState()
    data = b"foo foofoo   foo"
    @test run!(state, data) == [1:3]
    @test run!(state, data) == [5:7]
    @test run!(state, data) == [9:10]
    @test run!(state, data) == [12:16]
    @test run!(state, data) == []
    @test run!(state, data) == []

    @eval function run2!(state, data)
        ret = []
        p = state.p
        cs = state.cs
        p_end = p_eof = endof(data)
        $(generate_exec_code(machine, actions=actions, code=:inline))
        state.p = p
        state.cs = cs
        return ret
    end
    state = MachineState()
    @test run2!(state, data) == [1:3]
    @test run2!(state, data) == [5:7]
    @test run2!(state, data) == [9:10]
    @test run2!(state, data) == [12:16]
    @test run2!(state, data) == []
    @test run2!(state, data) == []
end

module Test7
    using Automa
    using Base.Test

    re1 = re"a.*b"
    machine = compile(re1)
    @eval function ismatch1(data)
        $(generate_init_code(machine))
        p_end = p_eof = endof(data)
        $(generate_exec_code(machine))
        return cs ∈ $(machine.final_states)
    end
    @test ismatch1(b"ab")
    @test ismatch1(b"azb")
    @test ismatch1(b"azzzb")
    @test !ismatch1(b"azzz")
    @test !ismatch1(b"zzzb")

    re2 = re"a\.*b"
    machine = compile(re2)
    @eval function ismatch2(data)
        $(generate_init_code(machine))
        p_end = p_eof = endof(data)
        $(generate_exec_code(machine))
        return cs ∈ $(machine.final_states)
    end
    @test ismatch2(b"ab")
    @test ismatch2(b"a.b")
    @test ismatch2(b"a...b")
    @test !ismatch2(b"azzzb")
    @test !ismatch2(b"a...")
    @test !ismatch2(b"...b")

    re3 = re"a\.\*b"
    machine = compile(re3)
    @eval function ismatch3(data)
        $(generate_init_code(machine))
        p_end = p_eof = endof(data)
        $(generate_exec_code(machine))
        return cs ∈ $(machine.final_states)
    end
    @test ismatch3(b"a.*b")
    @test !ismatch3(b"a...b")
end
