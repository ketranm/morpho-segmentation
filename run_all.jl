function run_all(params)
  outfile = params.outfile
  params.outfile = strcat(outfile,"1.dict")
  println("State 1 ...")
  state = run_gibbs(params)

  
  #println("State 2 ...")
  params.state0 = state
  params.num_tags = 5
  params.init_seg = "state"
  params.init_stem = "state"
  params.outfile = strcat(outfile,"2.dict")
  state = run_gibbs(params)

  println("State 3 ...")
  params.state0 = state
  params.cluster = read_cluster(cluster_file)
  params.init_tag = "state"
  params.outfile = strcat(outfile,"3.dict")
  state = run_gibbs(params)

end
