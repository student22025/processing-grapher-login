/* * * * * * * * * * * * * * * * * * * * * * *
 * GRAPH CLASS
 *
 * @file     Graph.pde
 * @brief    Class to draw graphs in Processing
 * @author   Simon Bluett
 *
 * @license  GNU General Public License v3
 * @class    Graph
 * * * * * * * * * * * * * * * * * * * * * * */

/*
 * Copyright (C) 2022 - Simon Bluett <hello@chillibasket.com>
 *
 * This file is part of ProcessingGrapher 
 * <https://github.com/chillibasket/processing-grapher>
 * 
 * ProcessingGrapher is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <https://www.gnu.org/licenses/>.
 */

class Graph {

	static public final int LINE_CHART = 0;
	static public final int DOT_CHART = 1;
	static public final int BAR_CHART = 2;

	// Content coordinates (left, right, top bottom)
	int cL, cR, cT, cB;
	int gL, gR, gT, gB;                // Graph area coordinates
	float gridX, gridY;                // Grid spacing
	float offsetLeft, offsetBottom;

	float minX, maxX, minY, maxY;      // Limits of data
	float[] lastX = {0};               // Arrays containing previous x and y values
	float[] lastY = {Float.MIN_VALUE};
	float xStep;

	float scaleFactor;
	float xRate;
	int plotType;
	String plotName;
	String xAxisName;
	//String yAxisName;

	// Ui variables
	int graphMark;
	int border;
	boolean redrawGraph;
	boolean gridLines;
	boolean squareGrid;
	boolean highlighted;

	PGraphics graphics;


	/**
	 * Constructor
	 *
	 * @param  canvas  The graphics canvas drawing object
	 * @param  left    Graph area left x-coordinate
	 * @param  right   Graph area right x-coordinate
	 * @param  top     Graph area top y-coordinate
	 * @param  bottom  Graph area bottom y-coordinate
	 * @param  minx    Minimum X-axis value on graph
	 * @param  maxx    Maximum X-axis value on graph
	 * @param  miny    Minimum Y-axis value on graph
	 * @param  maxy    Maximum Y-axis value on graph
	 * @param  name    Name/title of the graph
	 */
	Graph(PGraphics canvas, int left, int right, int top, int bottom, float minX, float maxX, float minY, float maxY, String name)
	{
		graphics = g;
		plotName = name;

		this.cL = left;
		this.gL = left;
		this.cR = right;
		this.gR = right;
		this.cT = top;
		this.gT = top;
		this.cB = bottom;
		this.gB = bottom;

		gridX = 0;
		gridY = 0;
		offsetLeft = cL;
		offsetBottom = cT;

		this.minX = minX;
		this.maxX = maxX;
		this.minY = minY;
		this.maxY = maxY;

		scaleFactor = 1;
		xRate = 100;
		xStep = 1.0 / xRate;

		graphMark = round(8 * scaleFactor);
		border = round(30 * scaleFactor);

		plotType = 0;
		redrawGraph = gridLines = true;
		squareGrid = false;
		highlighted = false;

		xAxisName = "";
		//yAxisName = "";
	}


	Graph(PGraphics canvas, int graphWidth, int graphHeight, float minX, float maxX, float minY, float maxY, String name)
	{
		this(g, 0, graphWidth, 0, graphHeight, minX, maxX, minY, maxY, name);
	}

	Graph(int left, int right, int top, int bottom, float minX, float maxX, float minY, float maxY, String name)
	{
		this(g, left, right, top, bottom, minX, maxX, minY, maxY, name);
	}

	Graph(int graphWidth, int graphHeight, float minX, float maxX, float minY, float maxY, String name)
	{
		this(g, 0, graphWidth, 0, graphHeight, minX, maxX, minY, maxY, name);
	}

	Graph(PGraphics canvas, int left, int right, int top, int bottom)
	{
		this(canvas, left, right, top, bottom, 0, 20, 0, 1, "Graph");
	}

	Graph(int left, int right, int top, int bottom)
	{
		this(g, left, right, top, bottom, 0, 20, 0, 1, "Graph");
	}

	Graph(PGraphics canvas, int graphWidth, int graphHeight)
	{
		this(canvas, 0, graphWidth, 0, graphHeight, 0, 20, 0, 1, "Graph");
	}

	Graph(int graphWidth, int graphHeight)
	{
		this(g, 0, graphWidth, 0, graphHeight, 0, 20, 0, 1, "Graph");
	}


	/**
	 * Change the graphics buffer onto which to draw the graph
	 *
	 * @param  newGraphics The processing graphics object to use
	 */
	void canvas(PGraphics newGraphics)
	{
		if (newGraphics != null)
		{
			graphics = newGraphics;
		}
	}


	/**
	 * Read which graphics buffer graph is currently being drawn onto
	 * 
	 * @return The current graphics buffer canvas
	 */
	PGraphics canvas()
	{
		return graphics;
	}
	

	/**
	 * Change graph content area dimensions
	 *
	 * @param  newL New left x-coordinate
	 * @param  newR New right x-coordinate
	 * @param  newT New top y-coordinate
	 * @param  newB new bottom y-coordinate
	 */
	void setSize(int newL, int newR, int newT, int newB)
	{
		cL = newL;
		cR = newR;
		cT = newT;
		cB = newB;
		graphMark = round(8 * scaleFactor);
		border = round(30 * scaleFactor);

		for(int i = 0; i < lastX.length; i++) lastX[i] = 0;
		redrawGraph = true;
	}


	/**
	 * Set the chart interface scaling factor
	 * 
	 * @param  factor  The scaling multiplication factor
	 */
	void scale(float factor)
	{
		if (factor > 0)
		{
			this.scaleFactor = factor;
		}
	}


	 /**
	  * Get the current chart interface scaling factor
	  * 
	  * @return  The chart scaling multiplication factor
	  */
	float scale()
	{
		return scaleFactor;
	}


	/**
	 * Get the data rate relating to Y-axis spacing
	 * of the live serial data graph
	 *
	 * @return Data rate in samples per second
	 */
	float frequency()
	{
		return xRate;
	}


	/**
	 * Set the data rate relating to Y-axis spacing
	 * of the live serial data graph
	 *
	 * @param  newrate Data rate in samples per second
	 * @return True if update is successful, false it number is invalid
	 */
	boolean frequency(float newrate)
	{
		if (valid(newrate) && (newrate > 0) && (newrate <= 10000))
		{
			xRate = newrate;
			xStep = 1.0 / xRate;
			return true;
		}
		else
		{
			println("Graph::setFrequency() - Invalid number: " + newrate);
			return false;
		}
	}


	/**
	 * Check if the X- and Y- graph axes are set to be the same scale
	 *
	 * @return  True/false to enable equal graph axes
	 */
	boolean getSquareGrid()
	{
		return squareGrid;
	}


	/**
	 * Set the X- and Y- graph axes to the same scale
	 *
	 * @param  value True/false to enable equal graph axes
	 */
	void setSquareGrid(boolean value)
	{
		squareGrid = value;
	}


	/**
	 * Set the title label for the X-axis
	 *
	 * @param  newName The text to be displayed beside the axis
	 */
	void xAxisTitle(String newName)
	{
		xAxisName = newName;
	}


	/**
	 * Get the current title label for the x-axis
	 * 
	 * @return  The current x-axis title text
	 */
	String xAxisTitle()
	{
		return xAxisName;
	}


	/**
	 * Set the name label for the Y-axis
	 *
	 * @param  newName The text to be displayed beside the axis
	 */
	//void setYaxisName(String newName) {
	//	yAxisName = newName;
	//}


	/**
	 * Set all the minimum and maximum limits of the graph axes
	 * 
	 * @param  minX  Minimum x-axis value
	 * @param  maxX  Maximum x-axis value
	 * @param  minY  Minimum y-axis value
	 * @param  maxY  Maximum y-axis value
	 */
	void limits(float minX, float maxX, float minY, float maxY)
	{
		if (valid(minX)) this.minX = minX;
		if (valid(maxX)) this.maxX = maxX;
		if (valid(minY)) this.minY = minY;
		if (valid(maxY)) this.maxY = maxY;
	}

	/**
	 * Set the minimum X-axis value
	 *
	 * @param  newValue The new x-axis minimum value
	 * @return True if update is successful, false if newValue is invalid
	 */
	boolean xMin(float newValue)
	{
		if (valid(newValue) && newValue < maxX)
		{
			minX = newValue;
			return true;
		}
		return false;
	}


	/**
	 * Set the maximum X-axis value
	 *
	 * @param  newValue The new x-axis maximum value
	 * @return True if update is successful, false if newValue is invalid
	 */
	boolean xMax(float newValue)
	{
		if (valid(newValue) && newValue > minX)
		{
			maxX = newValue;
			return true;
		}
		return false;
	}


	/**
	 * Set the minimum Y-axis value
	 *
	 * @param  newValue The new y-axis minimum value
	 * @return True if update is successful, false if newValue is invalid
	 */
	boolean yMin(float newValue)
	{
		if (valid(newValue) && newValue < maxY)
		{
			minY = newValue;
			return true;
		}
		return false;
	}


	/**
	 * Set the maximum Y-axis value
	 *
	 * @param  newValue The new y-axis maximum value
	 * @return True if update is successful, false if newValue is invalid
	 */
	boolean yMax(float newValue)
	{
		if (valid(newValue) && newValue > minY)
		{
			maxY = newValue;
			return true;
		}
		return false;
	}


	/**
	 * Functions to get the range of the X- or Y- axes
	 *
	 * @return The new minimum or maximum range value
	 */	
	float xMin() { return minX; }
	float xMax() { return maxX; }
	float yMin() { return minY; }
	float yMax() { return maxY; }


	/**
	 * Reset graph 
	 */
	void resetGraph(){
		for(int i = 0; i < lastX.length; i++) lastX[i] = -xStep;
		for(int i = 0; i < lastY.length; i++) lastY[i] = Float.MIN_VALUE;
	}


	/**
	 * Reset and remove all saved data
	 */
	void reset() {
		lastX = new float[0];
		lastY = new float[0];
	}


	/**
	 * Test whether a float number is valid
	 *
	 * @param  newNumber The number to test
	 * @return True if valid, false is number is NaN or Infinity
	 */
	private boolean valid(float newNumber)
	{
		if ((newNumber != newNumber) || (newNumber == Float.POSITIVE_INFINITY) || (newNumber == Float.NEGATIVE_INFINITY))
		{
			return false;
		}
		return true;
	}


	/**
	 * Draw a X-axis label onto the graph
	 * @{
	 * @param  xCoord       The X-coordinate on the screen
	 * @param  signalColor  The colour in which the label should be drawn
	 * @return The X-axis value of the label position on the graph
	 */
	float xLabel(int xCoord, color signalColor)
	{
		if (xCoord < gL || xCoord > gR) return 0;

		graphics.stroke(signalColor);
		graphics.strokeWeight(1 * scaleFactor);

		graphics.line(xCoord, gT, xCoord, gB);
		return map(xCoord, gL, gR, minX, maxX);
	}


	/**
	 * Draw a X-axis label onto the graph
	 *
	 * @param  dataX        The x-axis position of the label
	 * @param  signalColor  The colour in which the label should be drawn
	 */
	void xLabel(float dataX, color signalColor)
	{
		if (dataX >= minX && dataX <= maxX)
		{
			graphics.stroke(signalColor);
			graphics.strokeWeight(1 * scaleFactor);

			graphics.line(map(dataX, minX, maxX, gL, gR), gT, map(dataX, minX, maxX, gL, gR), gB);
		}
	}
	/** @} */


	/**
	 * Change the graph display type
	 *
	 * @param  type  The graph type to display
	 */
	void graphType(int type)
	{
		if (type >= 0 && type <= 2)
		{
			plotType = type;
		}
	}


	/**
	 * Get the type of graph which is currently being displayed
	 *
	 * @return  The graph type being displayed
	 */
	int graphType()
	{
		return plotType;
	}


	/**
	 * Show that current graph is active
	 *
	 * This function changes the colour of the graph name/title text
	 * to show that it has been selected.
	 *
	 * @param  state  Whether graph is selected or not
	 */
	void selected(boolean state)
	{
		highlighted = state;
	}


	/**
	 * See if the current graph is selected
	 * 
	 * @return  True if graph is selected, false otherwise
	 */
	boolean selected()
	{
		return highlighted;
	}


	/**
	 * Check if a window coordinate is in the graph area
	 *
	 * @param  xCoord The window X-coordinate
	 * @param  yCoord The window Y-coordinate
	 * @return True if coordinate is within the content area
	 */
	boolean onGraph(int xCoord, int yCoord)
	{
		if (xCoord >= cL && xCoord <= cR && yCoord >= cT && yCoord <= cB) return true;
		else return false;
	}


	/**
	 * Convert window coordinate into X-axis graph value
	 *
	 * @param  xCoord The window X-coordinate
	 * @return The graph X-axis value at this X-coordinate
	 */
	float xGraphPos(int xCoord)
	{
		if (xCoord < gL) xCoord = gL;
		else if (xCoord > gR) xCoord = gR;
		return map(xCoord, gL, gR, 0, 1);
	}


	/**
	 * Convert window coordinate into Y-axis graph value
	 *
	 * @param  yCoord The window Y-coordinate
	 * @return The graph Y-axis value at this Y-coordinate
	 */
	float yGraphPos(int yCoord)
	{
		if (yCoord < gT) yCoord = gT;
		else if (yCoord > gB) yCoord = gB;
		return map(yCoord, gT, gB, 0, 1);
	}


	/**
	 * Plot a new data point on the graph
	 *
	 * @param  dataY The Y-axis value of the data
	 * @param  dataX The X-axis value of the data
	 * @param  type  The signal ID/number
	 * @param  signalColor The colour which to draw the signal
	 * @{
	 */
	void plotData(float dataX, float dataY, int type, color signalColor)
	{

		if (valid(dataY) && valid(dataX)) {

			int x1, y1, x2 = gL, y2;

			// Ensure that the element actually exists in data arrays
			while(lastY.length < type + 1) lastY = append(lastY, Float.MIN_VALUE);
			while(lastX.length < type + 1) lastX = append(lastX, 0);
						
			// Redraw grid, if required
			if (redrawGraph) drawGrid();

			// Bound the Y-axis data
			if (dataY > maxY) dataY = maxY;
			if (dataY < minY) dataY = minY;

			// Bound the X-axis
			if (dataX > maxX) dataX = maxX;
			if (dataX < minX) dataX = minX;

			// Set colours
			graphics.fill(signalColor);
			graphics.stroke(signalColor);
			graphics.strokeWeight(1 * scaleFactor);

			switch(plotType)
			{
				case DOT_CHART:
				{
					// Determine x and y coordinates
					x2 = round(map(dataX, minX, maxX, gL, gR));
					y2 = round(map(dataY, minY, maxY, gB, gT));
					
					graphics.ellipse(x2, y2, 1*scaleFactor, 1*scaleFactor);
					break;
				}

				case BAR_CHART:
				{
					if (lastY[type] != Float.MIN_VALUE && lastY[type] != Float.MAX_VALUE) {
						graphics.noStroke();

						// Determine x and y coordinates
						x1 = round(map(lastX[type], minX, maxX, gL, gR));
						x2 = round(map(dataX, minX, maxX, gL, gR));
						y1 = round(map(dataY, minY, maxY, gB, gT));
						if (minY <= 0) y2 = round(map(0, minY, maxY, gB, gT));
						else y2 = round(map(minY, minY, maxY, gB, gT));

						// Figure out how wide the bar should be
						final int oneSegment = ceil((x2 - x1) / float(lastX.length));
						x1 += oneSegment * type;
						if (lastX.length > 1) x2 = x1 + oneSegment;
						else x2 = x1 + ceil(oneSegment / 1.5);
						
						graphics.rectMode(CORNERS);
						graphics.rect(x1, y1, x2, y2);
					}
					break;
				}

				case LINE_CHART:
				default: 
				{
					// Only draw line if last value is set
					if (lastY[type] != Float.MIN_VALUE) {
						// Determine x and y coordinates
						x1 = round(map(lastX[type], minX, maxX, gL, gR));
						x2 = round(map(dataX, minX, maxX, gL, gR));
						y1 = round(map(lastY[type], minY, maxY, gB, gT));
						y2 = round(map(dataY, minY, maxY, gB, gT));
						graphics.line(x1, y1, x2, y2);
					}
					break;
				}
			}
			
			lastY[type] = dataY;
			lastX[type] = dataX;
		}
	}


	/**
	 * Plot a new data point using default y-increment
	 *
	 * @note   This is an overload function
	 * @see    void plotData(float, float, int)
	 */
	void plotData(float dataY, int type) {
	
		// Ensure that the element actually exists in data arrays
		while(lastY.length < type + 1) lastY = append(lastY, Float.MIN_VALUE);
		while(lastX.length < type + 1) lastX = append(lastX, -xStep);
		plotData(lastX[type] + xStep, dataY, type);
	}


	/**
	 * Plot a new data point using default y-increment
	 *
	 * @note   This is an overload function
	 * @see    void plotData(float, float, int, color)
	 */
	void plotData(float dataX, float dataY, int type) {
		int colorIndex = type - (c_colorlist.length * floor(type / c_colorlist.length));
		plotData(dataX, dataY, type, c_colorlist[colorIndex]);
	}
	/** @} */	


	/**
	 * Plot a rectangle on the graph
	 *
	 * @param  dataY1 Y-axis value of top-left point
	 * @param  dataY2 Y-axis value of bottom-right point
	 * @param  dataX1 X-axis value of top-left point
	 * @param  dataX2 X-axis value of bottom-right point
	 * @param  type   The signal ID/number (this determines the colour)
	 */
	void plotRectangle(float dataY1, float dataY2, float dataX1, float dataX2, color areaColor) {

		// Only plot data if it is within bounds
		if (
			(dataY1 >= minY) && (dataY1 <= maxY) && 
			(dataY2 >= minY) && (dataY2 <= maxY) &&
			(dataX1 >= minX) && (dataX1 <= maxX) && 
			(dataX2 >= minX) && (dataX2 <= maxX)
		   )
		{
			// Get relevant color from list
			graphics.fill(areaColor);
			graphics.stroke(areaColor);
			graphics.strokeWeight(1 * scaleFactor);

			// Determine x and y coordinates
			final int x1 = round(map(dataX1, minX, maxX, gL, gR));
			final int x2 = round(map(dataX2, minX, maxX, gL, gR));
			final int y1 = round(map(dataY1, minY, maxY, gB, gT));
			final int y2 = round(map(dataY2, minY, maxY, gB, gT));
			
			graphics.rectMode(CORNERS);
			graphics.rect(x1, y1, x2, y2);
		}
	}


	/**
	 * Clear the graph area and redraw the grid lines
	 */
	void clearGraph()
	{
		// Clear the content area
		graphics.rectMode(CORNER);
		graphics.noStroke();
		graphics.fill(c_background);
		graphics.rect(gL, gT - (scaleFactor * 1), gR - gL + (scaleFactor * 1), gB - gT + (scaleFactor * 2));

		// Setup drawing parameters
		graphics.strokeWeight(1 * scaleFactor);
		graphics.stroke(c_graph_gridlines);

		// Draw X-axis grid lines
		if (gridLines && gridX != 0) {
			for (float i = offsetLeft; i < gR; i += gridX) {
				graphics.line(i, gT, i, gB);
			}
		}

		// Draw y-axis grid lines
		if (gridLines && gridY != 0) {
			for (float i = offsetBottom; i > gT; i -= gridY) {
				graphics.line(gL, i, gR, i);
			}
		}

		float yZero = 0;
		float xZero = 0;
		if      (minY > 0) yZero = minY;
		else if (maxY < 0) yZero = maxY;
		if      (minX > 0) xZero = minX;
		else if (maxX < 0) xZero = maxX;

		// Draw the graph axis lines
		graphics.stroke(c_graph_axis);
		graphics.line(map(xZero, minX, maxX, gL, gR), gT, map(xZero, minX, maxX, gL, gR), gB);
		graphics.line(gL, map(yZero, minY, maxY, gB, gT), gR, map(yZero, minY, maxY, gB, gT));

		// Clear all previous data positions
		resetGraph();
	}


	/**
	 * Round a number to the closest suitable axis division size
	 *
	 * The axis divisions should end in the numbers 1, 2, 2.5, or 5
	 * to ensure that the axes are easily interpretable
	 *
	 * @param  num  The approximate division size we are aiming for
	 * @return The closest idealised division size
	 */
	private double roundToIdeal(float num)
	{
		if(num == 0)
		{
			return 0;
		}

		final int n = 2;
		final double d = Math.ceil( Math.log10( (num < 0)? -num : num ) );
		final int power = n - (int)d;

		final double magnitude = Math.pow( 10, power );
		long shifted = Math.round( num * magnitude );

		// Apply rounding to nearest useful divisor
		if      (abs(shifted) > 75) shifted = (num < 0)? -100 : 100;
		else if (abs(shifted) > 30) shifted = (num < 0)? -50 : 50;
		else if (abs(shifted) > 23) shifted = (num < 0)? -25 : 25;
		else if (abs(shifted) > 15) shifted = (num < 0)? -20 : 20;
		else                        shifted = (num < 0)? -10 : 10; 

		return shifted / magnitude;
	}


	/**
	 * Calculate the precision with which the graph axes labels should be drawn
	 *
	 * @param  maxValue  The maximum axis value
	 * @param  minValue  The minimum axis value
	 * @param  segments  The step size with which the graph will be divided
	 * @return The number of significant digits to display
	 */
	private int calculateRequiredPrecision(double maxValue, double minValue, double segments)
	{
		if ((segments == 0) || (maxValue == minValue)) 
		{
			return 1;
		}

		double largeValue = (maxValue < 0)? -maxValue : maxValue;

		if ((maxValue == 0) || (-minValue > largeValue))
		{
			largeValue = (minValue < 0)? -minValue : minValue;
		}

		final double d1 = Math.floor( Math.log10( (segments < 0)? -segments : segments ) );
		final double d2 = Math.floor( Math.log10( largeValue ) );
		final double removeMSN = Math.round( (segments % Math.pow( 10, d1 )) / Math.pow( 10, d1 - 1 ) );

		int value = abs((int) d2 - (int) d1) + 1;

		if (removeMSN > 0 && removeMSN < 10)
		{
			value++;
		}

		//println(maxValue + "max " + minValue + "min (" + d2 + ")\t - \t" + segments + " seg (" + d1 + ")\t - \t" + value + "val, " + removeMSN + "segMSD " + Math.pow( 10, d1 ) + " " + ((segments % Math.pow( 10, d1 )) ));

		return value;
	}


	/**
	 * Determine whether axis label is shown in decimal or scientific format
	 *
	 * In general, the text will be in decimal notation if the number has
	 * less than 5 characters. It will be in scientific notation otherwise.
	 *
	 * @param  labelNumber The number to be displayed on the label
	 * @param  precision   The number of significant digits to display
	 * @return The formatted label text
	 */
	private String formatLabelText(double labelNumber, int precision)
	{
		// Scientific notation
		String labelScientific = String.format("%." + precision + "g", labelNumber);
		if (labelScientific.contains(".")) labelScientific = labelScientific.replaceAll("[0]+$", "").replaceAll("[.]+$", "");

		// Decimal notation
		String labelDecimal = String.format("%." + precision + "f", labelNumber);
		if (labelDecimal.contains(".")) labelDecimal = labelDecimal.replaceAll("[0]+$", "").replaceAll("[.]+$", "");

		// If decimal notation is shorter than 5 characters, use it
		if (labelDecimal.length() < 5 || (labelDecimal.charAt(0) == '-' && labelDecimal.length() < 6)) return labelDecimal;
		return labelScientific;
	}


	/**
	 * Draw the grid and axes of the graph
	 */
	void drawGrid()
	{
		redrawGraph = false;

		// Clear the content area
		graphics.rectMode(CORNER);
		graphics.noStroke();
		graphics.fill(c_background);
		graphics.rect(cL, cT, cR - cL, cB - cT);

		// Add border and graph title
		graphics.strokeWeight(1 * scaleFactor);
		graphics.stroke(c_graph_border);
		if (cT > round((tabHeight + 1) * scaleFactor)) graphics.line(cL, cT, cR, cT);
		if (cL > 1) graphics.line(cL, cT, cL, cB);
		graphics.line(cL, cB, cR, cB);
		graphics.line(cR, cT, cR, cB);		

		graphics.textAlign(LEFT, TOP);
		graphics.textFont(base_font);
		graphics.fill(c_lightgrey);
		if (highlighted) graphics.fill(c_red);
		graphics.text(plotName, cL + int(5 * scaleFactor), cT + int(5 * scaleFactor));

		// X and Y axis zero
		float yZero = 0;
		float xZero = 0;
		if      (minY > 0) yZero = minY;
		else if (maxY < 0) yZero = maxY;
		if      (minX > 0) xZero = minX;
		else if (maxX < 0) xZero = maxX;

		// Text width and height
		graphics.textFont(mono_font);
		final int padding = int(5 * scaleFactor);
		final int textHeight = int(graphics.textAscent() + graphics.textDescent() + padding);
		final float charWidth = graphics.textWidth("0");

		/* -----------------------------------
		 *     Define graph top and bottom
		 * -----------------------------------*/
		gT = cT + border + textHeight / 3;
		gB = cB - border - textHeight - graphMark;

		/* -----------------------------------
		 *     Calculate y-axis parameters 
		 * -----------------------------------*/
		// Figure out how many segments to divide the data into
		double y_segment = Math.abs(roundToIdeal((maxY - minY) * (textHeight * 2) / (gB - gT)));

		// Figure out a base reference for all the segments
		double y_basePosition = yZero;
		if (yZero > 0) y_basePosition = Math.ceil(minY / y_segment) * y_segment;
		else if (yZero < 0) y_basePosition = -Math.ceil(-maxY / y_segment) * y_segment;

		// Figure out how many decimal places need to be shown on the labels
		int y_precision = calculateRequiredPrecision(maxY, minY, y_segment);

		// Figure out where each of the labels should be drawn
		double y_bottomPosition = y_basePosition - (Math.floor((y_basePosition - minY) / y_segment) * y_segment);
		offsetBottom = map((float) y_bottomPosition, minY, maxY, gB, gT);
		gridY = map((float) y_bottomPosition, minY, maxY, gB, gT) - map((float) (y_bottomPosition + y_segment), minY, maxY, gB, gT);;

		// Figure out the width of the largest label so we know how much room to make
		int yTextWidth = 0;
		String lastLabel = "";
		for (double i = y_bottomPosition; i <= maxY; i += y_segment) {
			String label = formatLabelText(i, y_precision);
			if (label.equals(lastLabel)) y_precision++;
			int labelWidth = int(label.length() * charWidth);
			if (labelWidth > yTextWidth) yTextWidth = labelWidth;
			lastLabel = label;
		}

		/* -----------------------------------
		 *     Define graph left and right
		 * -----------------------------------*/
		gL = cL + border + yTextWidth + graphMark + padding;
		gR = cR - border;

		/* -----------------------------------
		 *     Calculate x-axis parameters 
		 * -----------------------------------*/
		boolean solved = false;
		double x_segment;
		int x_precision;
		int xTextWidth = int(charWidth * 3);
		double x_basePosition;
		double x_leftPosition;

		// Since the solution of the calculations determines the width of the labels,
		// which in turn influences the calculations, set up a loop so that the label
		// widths are increased in length until they all fit in the axis area.
		do {
			// Figure out how many segments to divide the data into
			x_segment = Math.abs(roundToIdeal((maxX - minX) * (xTextWidth * 3) / (gR - gL)));

			// Figure out a base reference for all the segments
			x_basePosition = xZero;
			if (xZero > 0) x_basePosition = Math.ceil(minX / x_segment) * x_segment;
			else if (xZero < 0) x_basePosition = -Math.ceil(-maxX / x_segment) * x_segment;

			// Figure out how many decimal places need to be shown on the labels
			x_precision = calculateRequiredPrecision(maxX, minX, x_segment);

			// Figure out where each of the labels should be drawn
			x_leftPosition = x_basePosition - (Math.floor((x_basePosition - minX) / x_segment) * x_segment);
			offsetLeft = map((float) x_leftPosition, minX, maxX, gL, gR);
			gridX = map((float) (x_leftPosition + x_segment), minX, maxX, gL, gR) - map((float) x_leftPosition, minX, maxX, gL, gR);

			// Figure out the width of the largest label so we know how much room to make
			int newxTextWidth = 0;
			lastLabel = "";
			for (double i = x_leftPosition; i <= maxX; i += x_segment) {
				String label = formatLabelText(i, x_precision);
				if (label.equals(lastLabel)) x_precision++;
				int labelWidth = int(label.length() * charWidth);
				if (labelWidth > newxTextWidth) newxTextWidth = labelWidth;
				lastLabel = label;
			}

			if (newxTextWidth <= xTextWidth) solved = true;
			else xTextWidth = newxTextWidth;
		} while (!solved);

		graphics.fill(c_lightgrey);

		//if (yAxisName != "") {
		//	graphics.textAlign(CENTER, CENTER);
		//	graphics.pushMatrix();
		//	graphics.translate(border / 2, (gB + gT) / 2);
		//	graphics.rotate(-HALF_PI);
		//	graphics.text("Some text here",0,0);
		//	graphics.popMatrix();
		//}

		// ---------- Y-AXIS ----------
		graphics.textAlign(RIGHT, CENTER);

		for (double i = y_bottomPosition; i <= maxY; i += y_segment) {
			final float currentYpixel = map((float) i, minY, maxY, gB, gT);

			if (gridLines) {
				graphics.stroke(c_graph_gridlines);
				graphics.line(gL, currentYpixel, gR, currentYpixel);
			}

			String label = formatLabelText(i, y_precision);

			graphics.stroke(c_graph_axis);
			graphics.text(label, gL - graphMark - padding, currentYpixel - (1 * scaleFactor));
			graphics.line(gL - graphMark, currentYpixel, gL - round(1 * scaleFactor), currentYpixel);

			// Minor graph lines
			if (i > y_bottomPosition) {
				final float minorYpixel = map((float) (i - (y_segment / 2.0)), minY, maxY, gB, gT);
				graphics.line(gL - (graphMark / 2.0), minorYpixel, gL - round(1 * scaleFactor), minorYpixel);
			}
		}


		// ---------- X-AXIS ----------
		graphics.textAlign(CENTER, TOP);
		if (xAxisName != "") graphics.text(xAxisName, (gL + gR) / 2, cB - border + padding);

		// Move right first
		for (double i = x_leftPosition; i <= maxX; i += x_segment)
		{
			final float currentXpixel = map((float) i, minX, maxX, gL, gR);

			if (gridLines)
			{
				graphics.stroke(c_graph_gridlines);
				graphics.line(currentXpixel, gT, currentXpixel, gB);
			}

			final String label = formatLabelText(i, x_precision);
			graphics.stroke(c_graph_axis);
			graphics.line(currentXpixel, gB, currentXpixel, gB + graphMark);

			if (i != maxX)
			{
				graphics.text(label, currentXpixel, gB + graphMark + padding);
			}

			// Minor graph lines
			if (i > x_leftPosition)
			{
				final float minorXpixel = map((float) (i - (x_segment / 2.0)), minX, maxX, gL, gR);
				graphics.line(minorXpixel, gB, minorXpixel, gB + (graphMark / 2.0));
			}
		}

		// The outer grid axes
		graphics.stroke(c_graph_axis);
		graphics.line(map(xZero, minX, maxX, gL, gR), gT, map(xZero, minX, maxX, gL, gR), gB);
		graphics.line(gL, map(yZero, minY, maxY, gB, gT), gR, map(yZero, minY, maxY, gB, gT));
		graphics.textFont(base_font);
	}
}
