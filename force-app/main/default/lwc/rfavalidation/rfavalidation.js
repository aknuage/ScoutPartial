import { LightningElement, api, wire} from 'lwc';
import docxImport from "@salesforce/resourceUrl/docx";
import {loadScript} from "lightning/platformResourceLoader";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import grabRFAParcels from "@salesforce/apex/RFAvalidation.getAllRelatedParcels";

const FIELDS = ['Request_for_Agreement__c.Grantee_Name__c', 'Request_for_Agreement__c.Lease_Version_Document_Name__c',
    'Request_for_Agreement__c.Spouse_Information__c','Request_for_Agreement__c.Land_Owner_Information__c',
    'Request_for_Agreement__c.Title_Clear__c','Request_for_Agreement__c.Title_Issues_Comments__c',
    'Request_for_Agreement__c.Agreement_Type__c',
    'Request_for_Agreement__c.Signing_Authority_Documents_Obtained__c',
    'Request_for_Agreement__c.Comments_for_Title_Doc_Prep__c',
    'Request_for_Agreement__c.Acreage_Being_Signed__c']


export default class Rfavalidation extends LightningElement {

    @api recordId;
    downloadURL;
    filename;
    getGname;
    getLeaseVersion;
    getSpouse;
    getLandOwnerInfo;
    getTitleClear;
    getTitleIssues;
    getSigning;
    getAgreementType;
    getCommentsPrep;
    getTotalAcreage;
    
    
    
    _no_border = {top: {style: "none", size: 0, color: "FFFFFF"},
	bottom: {style: "none", size: 0, color: "FFFFFF"},
	left: {style: "none", size: 0, color: "FFFFFF"},
	right: {style: "none", size: 0, color: "FFFFFF"}};

    connectedCallback(){
        Promise.all([loadScript(this, docxImport)]).then(() =>{
            this.renderButtons();
        });
    }

    renderButtons(){
        this.template.querySelector(".hidden").classList.add("not_hidden");
        this.template.querySelector(".hidden").classList.remove("hidden");
    }
    isLoading;
    async startDocumentGeneration(){
        console.log('Starting doc');
       // this.buildDocument();
        this.isLoading = true;
       try {
           const rfaList = await grabRFAParcels({'RFAId': this.recordId});
           if (rfaList.length === 0){
               this.showToastRfaError(); // exit if somehow no records were returned
               return;
           }
           const rfa = rfaList[0];
           console.log('RFA Parcels ==>', JSON.stringify(rfa, null, '\t'));
           this.getGname = rfa.Grantee_Name__c??'';
           this.getLeaseVersion = rfa.Lease_Version_Document_Name__c??'';
           this.getSpouse= rfa.Spouse_Information__c??'';
           this.getLandOwnerInfo= rfa.Land_Owner_Information__c??'';
           this.getTitleClear= rfa.Title_Clear__c??'';
           this.getTitleIssues= rfa.Title_Issues_Comments__c??'';
           this.getSigning= rfa.Signing_Authority_Documents_Obtained__c??'';
           this.getCommentsPrep = rfa.Comments_for_Title_Doc_Prep__c??'';
           this.getAgreementType= rfa.Agreement_Type__c??'';
           this.getTotalAcreage = rfa.Acreage_Being_Signed__c??'';
           
           this.filename = "RFA Summary - " + this.getGname + " " + this.getLeaseVersion+".docx";
           this.buildDocument(rfa.Agreement_Parcels__r);
       } catch (error) {
            console.error(error);
       } finally {
            this.isLoading = false;
       }
    }

    showToastRfaError() {
        const event = new ShowToastEvent({
            title: 'Error Generating RFA Document',
            variant: 'error',
            mode: 'dismissable',
            message:
                'Null RFA returned.',
        });
        this.dispatchEvent(event);
    }

    buildDocument(RFAParcelsPassed){
        console.log('Starting build with ' );
        let document = new docx.Document();
        let tableCells = [];
        let tempBodyLine;
        let createBody=[];
        //tableCells.push(this.generateHeaderRow());
       // let gnamestring = getFieldValue(data, Request_for_Agreement__c.Grantee_Name__c);
     console.log('lost guy: ' + this.getGname);

       
        
        
        console.log('Gname: ' );
        
        tableCells.push(this.generateRow("Project Name:  ", this.getGname));
        tableCells.push(this.generateRow("  ", "   "));
         
        tableCells.push(this.generateRow("Form:  ", this.getLeaseVersion));
        tableCells.push(this.generateRow("Agreement Type:  ", this.getAgreementType));
        tableCells.push(this.generateRow("  ", "   "));


        tableCells.push(this.generateRow("Land owner Information:  ", this.getLandOwnerInfo));
        tableCells.push(this.generateRow("  ", "   "));
     

        tableCells.push(this.generateRow("Spousal information: ", this.getSpouse));
        tableCells.push(this.generateRow("  ", "   "));
        tableCells.push(this.generateRow("Signing authority docs obtained?  ", this.getSigning));
        tableCells.push(this.generateRow("  ", "   "));
        tableCells.push(this.generateRow("Title Clear?  ", this.getTitleClear));
        tableCells.push(this.generateRow("Title Issues Comments:  ", this.getTitleIssues));
        tableCells.push(this.generateRow("  ", "   "));
        tableCells.push(this.generateRow("  ", "   "));
        tableCells.push(this.generateRow("Comments for Title & Doc Prep:  ", this.getCommentsPrep));
        tableCells.push(this.generateRow("  ", "   "));
        tableCells.push(this.generateRow("  ", "   "));
        tableCells.push(this.generateRow("Total Acreage:  ", this.getTotalAcreage));
        tableCells.push(this.generateRow("  ", "   "));
        tableCells.push(this.generateRow("Detail Parcel Information", "   "));
        

        RFAParcelsPassed.forEach(rfaparcelsRecord => {
            tableCells.push(this.generateParcelRow(rfaparcelsRecord, 1));
            tableCells.push(this.generateParcelRow(rfaparcelsRecord, 2));
            tableCells.push(this.generateParcelRow(rfaparcelsRecord, 3));
            tableCells.push(this.generateParcelRow(rfaparcelsRecord, 4));
            tableCells.push(this.generateParcelRow(rfaparcelsRecord, 5));
            tableCells.push(this.generateRow("  ", "   "));
            tableCells.push(this.generateRow("  ", "   "));
            tableCells.push(this.generateRow("  ", "   "));
        });
        

        //tempBodyLine = this.generateText("Hero");
        //console.log("tempbodyLine: " + tempBodyLine);
        //createBody.push(this.tempBodyLine);
        console.log("tablecell: " + tableCells);
       
        this.generateTable(document, tableCells);

        //let yoho = this.generateTextRun("Yo HO HO");
       // console.log('yoho: ' + yoho);
        

        this.generateDownloadLink(document);
    }

    generateHeaderRow(){
        let tableHeaderRow = new docx.TableRow({
            children:[
                new docx.TableCell({
                    children: [new docx.Paragraph("Field")],
                    borders: this._no_border
                }),
                new docx.TableCell({
                    children: [new docx.Paragraph("Value")],
                    borders: this._no_border
                }) 
            ]
        });

        return tableHeaderRow;
    }

    generateRow(fieldname,fieldValue){
        let tableRow = new docx.TableRow({
            children: [
                new docx.TableCell({
                    children: [new docx.Paragraph(fieldname)],
                    borders: this._no_border
                }),
                new docx.TableCell({
                    children: [new docx.Paragraph(fieldValue)],
                    borders: this._no_border
                })
            ]
        });

        return tableRow;
    }

    generateParcelRow(rfaParcelRecord, rowvar){
     if (rowvar ==1){
        let tableRow = new docx.TableRow({
            children: [
                new docx.TableCell({
                    children: [new docx.Paragraph("PIN:  ")],
                    borders: this._no_border
                }),
                new docx.TableCell({
                    children: [new docx.Paragraph({children: [this.generateTextRun(rfaParcelRecord["Parcel_ID_Local__c"]?.toString())]})],
                    borders: this._no_border
                })
            ]
        });
        return tableRow;
    } else if(rowvar==2){
        let tableRow = new docx.TableRow({
            children: [
                new docx.TableCell({
                    children: [new docx.Paragraph("Acreage (deed):  ")],
                    borders: this._no_border
                }),
                new docx.TableCell({
                    children: [new docx.Paragraph({children: [this.generateTextRun(rfaParcelRecord["Deed_Acres__c"]?.toString())]})],
                    borders: this._no_border
                })
            ]
        });
        return tableRow;
    } else if(rowvar==3){
        let tableRow = new docx.TableRow({
            children: [
                new docx.TableCell({
                    children: [new docx.Paragraph("Acreage (GIS):  ")],
                    borders: this._no_border
                }),
                new docx.TableCell({
                    children: [new docx.Paragraph({children: [this.generateTextRun(rfaParcelRecord["GIS_Acres__c"]?.toString())]})],
                    borders: this._no_border
                })
            ]
        });
        return tableRow;
    }
    else if(rowvar==4){
        let tableRow = new docx.TableRow({
            children: [
                new docx.TableCell({
                    children: [new docx.Paragraph("County:  ")],
                    borders: this._no_border
                }),
                new docx.TableCell({
                    children: [new docx.Paragraph({children: [this.generateTextRun(rfaParcelRecord["County__c"]?.toString())]})],
                    borders: this._no_border
                })
            ]
        });
        return tableRow;
    }
    else if(rowvar==5){
        let tableRow = new docx.TableRow({
            children: [
                new docx.TableCell({
                    children: [new docx.Paragraph("State  ")],
                    borders: this._no_border
                }),
                new docx.TableCell({
                    children: [new docx.Paragraph({children: [this.generateTextRun(rfaParcelRecord["State__c"]?.toString())]})],
                    borders: this._no_border
                })
            ]
        });
        return tableRow;
    }
    
        
    }
    generateParcelRowB(rfaParcelRecord){     
        let tableRow = new docx.TableRow({
            children: [
                new docx.TableCell({
                    children: [new docx.Paragraph({children: [this.generateTextRun(rfaParcelRecord["GIS_Acres__c"].toString())]})],
                    borders: this._no_border
                })
            ]
        });      

        return tableRow;        
    }

    generateTextRun(cellString){
        let textRun = new docx.TextRun({text: cellString});
        //let textRun = new docx.TextRun({text: cellString, bold: true, size: 10, font: "Calibri"});
        return textRun;
    }

    generateParagraph(cellString){
        let textRun = new docx.TextRun({text: cellString, bold: true, size: 10, font: "Calibri"});
        return textRun;
    }

    generateTable(documentPassed, tableCellsPassed){
        let docTable = new docx.Table({
            rows: tableCellsPassed
        });

        /*
        let setText = new docx.Paragraph({
            style: "text",
            children: [
                new docx.TextRun({
                    text: 'This TEXT is so long that the break is not at the end of the line'
                })
            ]
        });
        */

        documentPassed.addSection({
            //children: [docTable, passedBody]
            children: [docTable]
        });
    }

    generateText(addText) {
    let setText = new docx.Paragraph({
        style: "text",
        children: [
            new docx.TextRun({
                text: this.getGname,
                break: 1,
            }),
           
            new docx.TextRun({
                text: this.getLeaseVersion,
                break: 1,
            }),
          
            new docx.TextRun({
                text: this.getSpouse,
                break: 1,
            }),
              
            new docx.TextRun({
                text: this.getLandOwnerInfo,
                break: 1,
            }),
            new docx.TextRun({
                text: this.getTitleClear,
                break: 1,
            }),
            new docx.TextRun({
                text: this.getTitleIssues,
                break: 1,
            }),new docx.TextRun({
                text: this.getSigning,
                break: 1,
            }),new docx.TextRun({
                text: this.getAgreementType,
                break: 1,
            })
                
        ]
    });
    
    return setText;
    }

    generateSection(documentPassedA){
        let setText = new docx.Paragraph({
            style: "text",
            children: [
                new docx.TextRun({
                    text: 'This text is shorter that the break is not at the end of the line'
                })
            ]
        });
        return setText;
/*
        documentPassedA.addSection({
            children: [setText]
        });
        */
    }

  


    generateDownloadLink(documentPassed){
        docx.Packer.toBase64String(documentPassed).then(textBlob =>{
            this.downloadURL = 'data:application/vnd.openxmlformats-officedocument.wordprocessingml.document;base64,' + textBlob;
            this.template.querySelector(".slds-hide")?.classList.remove("slds-hide");
        });
    }
}