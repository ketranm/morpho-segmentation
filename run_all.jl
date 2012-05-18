function run_all(params)
  outfile = params.outfile
  params.outfile = strcat(outfile,"1.dict")
  println("State 1 ...")
  state = run_gibbs(params)

  
  println("State 2 ...")
  params.state0 = state
  params.num_tags = 5
  params.init_seg = "state"
  params.init_stem = "state"
  params.outfile = strcat(outfile,"2.dict")
  state = run_gibbs(params)
  #print_distr(state.distr_type_tag)

  println("State 3 ...")
  params.state0 = state
  params.seq =  true
  params.init_tag = "state"
  params.outfile = strcat(outfile,"3.dict")
  state = run_gibbs(params)
  #print_distr(state.distr_type_tag)

  println("State 4 ...")
  params.state0 = state
  params.use_suffix = true
  params.outfile = strcat(outfile,"4.dict")
  state = run_gibbs(params)
  #print_distr(state.distr_type_tag)
end
