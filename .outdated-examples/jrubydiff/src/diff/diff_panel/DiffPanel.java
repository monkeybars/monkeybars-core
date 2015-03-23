/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

/*
 * DiffPanel.java
 *
 * Created on 2009-3-12, 15:52:04
 */

package diff.diff_panel;

import java.awt.Dimension;
import java.awt.FontMetrics;
import java.awt.Graphics;
import java.awt.GraphicsEnvironment;
import java.awt.image.BufferedImage;

/**
 *
 * @author daiwhea
 */
public class DiffPanel extends javax.swing.JPanel {

    /** Creates new form DiffPanel */
    public DiffPanel() {
        initComponents();
    }

    private Dimension get_text_preferred_size() {
        Graphics g = GraphicsEnvironment.getLocalGraphicsEnvironment().createGraphics(new BufferedImage(100, 100, BufferedImage.TYPE_INT_RGB));
        FontMetrics fm = g.getFontMetrics(getFont());
        System.out.println("[[["+fm.charWidth(0x77) * 81+","+((fm.getHeight() + fm.getLeading()) * 12)+"]]]");
        Dimension size = new Dimension(fm.charWidth(0x77) * 81, (fm.getHeight() + fm.getLeading()) * 12);
        setSize(size);
        return size;
    }

    /** This method is called from within the constructor to
     * initialize the form.
     * WARNING: Do NOT modify this code. The content of this method is
     * always regenerated by the Form Editor.
     */
    @SuppressWarnings("unchecked")
    // <editor-fold defaultstate="collapsed" desc="Generated Code">//GEN-BEGIN:initComponents
    private void initComponents() {

        jPanel2 = new javax.swing.JPanel();
        title = new javax.swing.JLabel();
        jPanel1 = new javax.swing.JPanel();
        scroll_panel = new javax.swing.JScrollPane();
        diff_panel = new diff.diff_panel.MyTextPanel();

        title.setText("jLabel1");

        org.jdesktop.layout.GroupLayout jPanel2Layout = new org.jdesktop.layout.GroupLayout(jPanel2);
        jPanel2.setLayout(jPanel2Layout);
        jPanel2Layout.setHorizontalGroup(
            jPanel2Layout.createParallelGroup(org.jdesktop.layout.GroupLayout.LEADING)
            .add(title, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, 354, Short.MAX_VALUE)
        );
        jPanel2Layout.setVerticalGroup(
            jPanel2Layout.createParallelGroup(org.jdesktop.layout.GroupLayout.LEADING)
            .add(jPanel2Layout.createSequentialGroup()
                .add(title, org.jdesktop.layout.GroupLayout.PREFERRED_SIZE, 15, Short.MAX_VALUE)
                .addContainerGap())
        );

        jPanel1.setBackground(java.awt.Color.white);

        scroll_panel.setBackground(java.awt.Color.WHITE);
        scroll_panel.setViewportView(diff_panel);

        org.jdesktop.layout.GroupLayout jPanel1Layout = new org.jdesktop.layout.GroupLayout(jPanel1);
        jPanel1.setLayout(jPanel1Layout);
        jPanel1Layout.setHorizontalGroup(
            jPanel1Layout.createParallelGroup(org.jdesktop.layout.GroupLayout.LEADING)
            .add(org.jdesktop.layout.GroupLayout.TRAILING, scroll_panel, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, 354, Short.MAX_VALUE)
        );
        jPanel1Layout.setVerticalGroup(
            jPanel1Layout.createParallelGroup(org.jdesktop.layout.GroupLayout.LEADING)
            .add(scroll_panel, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, 237, Short.MAX_VALUE)
        );

        org.jdesktop.layout.GroupLayout layout = new org.jdesktop.layout.GroupLayout(this);
        this.setLayout(layout);
        layout.setHorizontalGroup(
            layout.createParallelGroup(org.jdesktop.layout.GroupLayout.LEADING)
            .add(jPanel2, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
            .add(jPanel1, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
        );
        layout.setVerticalGroup(
            layout.createParallelGroup(org.jdesktop.layout.GroupLayout.LEADING)
            .add(layout.createSequentialGroup()
                .add(jPanel2, org.jdesktop.layout.GroupLayout.PREFERRED_SIZE, 13, org.jdesktop.layout.GroupLayout.PREFERRED_SIZE)
                .addPreferredGap(org.jdesktop.layout.LayoutStyle.RELATED)
                .add(jPanel1, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, org.jdesktop.layout.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE))
        );
    }// </editor-fold>//GEN-END:initComponents


    // Variables declaration - do not modify//GEN-BEGIN:variables
    private diff.diff_panel.MyTextPanel diff_panel;
    private javax.swing.JPanel jPanel1;
    private javax.swing.JPanel jPanel2;
    private javax.swing.JScrollPane scroll_panel;
    private javax.swing.JLabel title;
    // End of variables declaration//GEN-END:variables

}
