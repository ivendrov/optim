--[[ An implementation of RMSprop

ARGS:

- 'opfunc' : a function that takes a single input (X), the point
             of a evaluation, and returns f(X) and df/dX
- 'x'      : the initial point
- 'config` : a table with configuration parameters for the optimizer
- 'config.learningRate'      : learning rate
- 'config.alpha'             : smoothing constant
- 'config.epsilon'           : value with which to inistialise m
- 'config.momentum'          : value of Nesterov momentum to use
- 'state'                    : a table describing the state of the optimizer;
                               after each call the state is modified
- 'state.m'                  : leaky sum of squares of parameter gradients,
- 'state.tmp'                : and the square root (with epsilon smoothing)
- 'state.v'                  : velocity vector

RETURN:
- `x`     : the new x vector
- `f(x)`  : the function, evaluated before the update

]]

function optim.rmsprop(opfunc, x, config, state)
    -- (0) get/update state
    local config = config or {}
    local state = state or config
    local lr = config.learningRate or 1e-2
    local alpha = config.alpha or 0.99
    local epsilon = config.epsilon or 1e-8
    local momentum = config.momentum or 0
    
    -- (0) make Nesterov momentum update (BEFORE evaluation)
    if momentum then
      -- initialize velocity vector
      if not state.v then
        state.v = torch.Tensor():typeAs(x):resizeAs(x):zero()
      end
      x:add(momentum, state.v)
    end

    -- (1) evaluate f(x) and df/dx
    local fx, dfdx = opfunc(x)
    
    if momentum then
      -- undo Nesterov step
      x:add(-momentum, state.v)
    end
      
    -- (2) initialize mean square values and square gradient storage
    if not state.m then
      state.m = torch.Tensor():typeAs(x):resizeAs(dfdx):zero()
      state.tmp = torch.Tensor():typeAs(x):resizeAs(dfdx)
    end

    -- (3) calculate new (leaky) mean squared values
    state.m:mul(alpha)
    state.m:addcmul(1.0-alpha, dfdx, dfdx)
    
    -- (4) perform update
    state.tmp:sqrt(state.m):add(epsilon)
    
    if momentum then
      -- update velocity
      state.v:mul(momentum)
      state.v:addcdiv(-lr, dfdx, state.tmp)
      
      -- update position
      x:add(state.v)
    else
      x:addcdiv(-lr, dfdx, state.tmp)
    end

    -- return x*, f(x) before optimization
    return x, {fx}
end
