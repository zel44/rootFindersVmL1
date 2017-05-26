d = document
result = d.getElementById 'result'

console.log = (line) -> result.value += line + '\n'

start = d.getElementById 'start'
start.addEventListener 'click', () ->
	result.value = ''
	funStr = (d.getElementById 'equation').value || "x^3-3x^2-x+4"
	a = parseFloat (d.getElementById 'a').value || -2
	b = parseFloat (d.getElementById 'b').value || 3
	step = parseFloat (d.getElementById 'step').value || 0.5
	e = parseFloat (d.getElementById 'e').value || 0.01
	# next chunk gives array [ [ factor, power ], ...] asc sorted by power
	# [ 2, 4 ] == 2x^4
	reg = /([+-]?\d*)[a-z](?:\^([+-]?\d+))?/g
	funStr = funStr.split(' ').join('')
	parsedFun = while match = reg.exec funStr
		[parseFloat(match[1]) or parseFloat(match[1] + 1), parseFloat(match[2]) or 1]
	reg = /($|[+-]\d*)(?:$|[+-])/
	match = reg.exec funStr
	(m = match[1]) and parsedFun.push [ parseFloat(m), 0]
	parsedFun.sort (a, b) -> a[1] - b[1]
	parsedF = []

	f = (x, parsedF = parsedFun, pow) ->
		sum = 0
		sum += el[0] * Math.pow x, el[1] for el in parsedF
		if pow? then Math.pow sum, pow else sum

	fDeriv = (x, rate, parsedF = parsedFun) ->
		sum = 0
		for el in parsedF
			t = 1
			if el[1] < rate then continue
			t *= el[1] - i for i in [0...rate]
			sum += el[0] * t * Math.pow x, (el[1] - rate)
		sum

	getSegments = () ->
		segments = []
		prev = 0
		for i in [a..b] by step
			if (next = f i) == 0 then segments.push [i] else
				if prev * next < 0 then segments.push [i - step, i]
			prev = next
		segments

	halfDiv = (a, b) ->
		while (Math.abs a-b) > e
			fa = f a
			fb = f b
			c = (a + b) / 2
			fc = f c
			if fa * fc < 0 then b = c else a = c
			[c]

	chordMet = (a, b) ->
		fa = f a
		fb = f b
		c = (a*fb - b*fa) / (fb - fa)
		fc = f c
		if (fa) * (fc) < 0 then [x0, fx0] = [a, fa] else [x0, fx0] = [b, f b]
		results = []
		while (Math.abs fc) > e
			c = (x0*fc - c*fx0) / (fc - fx0)
			fc = f c
			[c]

	newtMet = (a, b) ->
		fa = f a
		if (fa * fDeriv a, 2) > 0 then x = a else x = b
		x0 = Infinity
		while (Math.abs x-x0) > e
			x0 = x
			[x = x - (f x) / fDeriv(x, 1)]

	modNewtMet = (a, b) ->
		fa = f a
		fb = f b
		if (fa * fDeriv a, 2) > 0 then [x, fx0] = [a, fa] else [x, fx0] = [b, fb]
		x0 = Infinity
		dfx0 = fDeriv(x, 1)
		while (Math.abs x-x0) > e
			x0 = x
			[x = x - (f x) / dfx0]

	print = (name, arr) ->
		console.log name
		if not arr? or arr.length == 0
			console.log "\tdiverged!!!"
			return
		for el, ind in arr
			if el.length == 2
				console.log "\t#{ind + 1}. [#{el[0].toFixed 4} ; #{el[1].toFixed 4}]"
			else
				console.log "\t#{ind + 1}. #{el[0].toFixed 4}"

	printFinal = (name, arr) ->
		console.log "\t" + name
		if not arr? or arr.length == 0
			console.log "\tdiverged!!!"
			return
		console.log "\t#{arr[arr.length-1][0].toFixed 4}"

	segments = do getSegments
	# console.log segments
	if not segments.length
		console.log "no roots"
		return
	print "Segments with root", segments
	for segment, ind in segments
		if segment.length < 2 then continue
		[a, b] = segment
		console.log "for #{ind+1} segment:"
		printFinal "division by half", halfDiv a, b
		printFinal "chord method", chordMet a, b
		printFinal "newton method", newtMet a, b
		printFinal "modified newton method", modNewtMet a, b

	getDataArray = (f, a, b, step) ->
		dataArray = [ [ 'x', 'y'] ]
		x = a
		while x <= b
			dataArray.push [ x, f x ]
			x += step
		dataArray

	drawChart = ->
		dataArray = getDataArray(f, a-2, b+2, e)
		data = google.visualization.arrayToDataTable(dataArray)
		options =
			title: funStr
			curveType: 'function'
			legend:
				position: 'bottom'
			height: 1000
		chart = new google.visualization.LineChart document.getElementById('chart')
		chart.draw data, options
		return

	google.charts.load 'current', 'packages': [ 'corechart' ]
	google.charts.setOnLoadCallback drawChart